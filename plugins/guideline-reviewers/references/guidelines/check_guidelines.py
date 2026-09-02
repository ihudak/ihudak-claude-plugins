#!/usr/bin/env python3
"""
Automated UI guideline compliance checker.

Scans front-end source for violations of the guideline reference files that sit
beside this script (accessibility.md, appheader.md, datatable.md, filterfield.md,
settings.md, alerting-terminology.md) and reports findings.

The checks are deliberately design-system agnostic: they match the generic
component vocabulary used by the guidelines (app header / top app bar, data
table, filter field, ...) plus the common naming variants shipped by Material,
Fluent, and Apple-derived component libraries. Every match is a heuristic — the
output is a starting point for a human or agent review, not a verdict.

Usage:
    python3 check_guidelines.py /path/to/code/
    python3 check_guidelines.py /path/to/code/ --guideline appheader
    python3 check_guidelines.py /path/to/code/ --output json
    python3 check_guidelines.py --list
"""

import os
import re
import sys
import json
import argparse
from pathlib import Path
from dataclasses import dataclass, field, asdict
from typing import Optional


# --- Generic component vocabulary -------------------------------------------
# Guidelines name components generically; real codebases name them after
# whichever design system they use. These patterns bridge the two.

APP_HEADER_RE = re.compile(
    r'\b(AppHeader|AppBar|TopAppBar|TopBar|NavigationBar|NavBar|PageHeader|Masthead|HeaderBar)\w*\b'
)
HELP_ENTRY_RE = re.compile(r'\b(HelpMenu|HelpButton|HelpIcon|HelpEntry)\w*\b|["\']Help["\']')
HEADER_MENUS_RE = re.compile(r'\b(Menus|MenuBar|ActionItems|HeaderActions|Toolbar)\w*\b')
SETTINGS_ENTRY_RE = re.compile(r'\b(Setting|Settings|Preferences|Gear|Cog)(Icon|Menu|Button)\w*\b')

DATA_TABLE_RE = re.compile(
    r'\b(DataTable|DataGrid|TableView|VirtualTable|GridView)\w*\b|<Table\b|role=["\']grid["\']'
)
LOADING_RE = re.compile(r'\b(isLoading|loading|Skeleton|ProgressBar|ProgressCircle|Spinner|busy)\w*\b',
                        re.IGNORECASE)
EMPTY_STATE_RE = re.compile(r'\b(EmptyState|emptyState|noDataState|NoData|placeholderEmpty)\w*\b')
SORT_RE = re.compile(r'\b(sortable|onSort|sortBy|sortDirection|sortOrder)\w*\b')
ARIA_SORT_RE = re.compile(r'aria-sort')

ADVANCED_FILTER_RE = re.compile(r'\b(FilterField|FilterInput|QueryInput|QueryBar|AdvancedFilter)\w*\b')
SIMPLE_FILTER_RE = re.compile(r'\b(FilterBar|FacetFilter|FilterChips|SimpleFilter|FilterPanel)\w*\b')
DEBOUNCE_RE = re.compile(r'\b(debounce|useDebounce|debounced|setTimeout|throttle)\w*\b', re.IGNORECASE)
ABORT_RE = re.compile(r'\b(AbortController|abortSignal|CancelToken|cancelPrevious)\w*\b')

ICON_ONLY_BUTTON_RE = re.compile(
    r'<(Button|IconButton|ActionButton|ToolbarButton|button)\b[^>]*>\s*'
    r'<[A-Za-z]*Icon\b[^>]*/>\s*'
    r'</(?:Button|IconButton|ActionButton|ToolbarButton|button)>'
)
SELF_CLOSING_ICON_BUTTON_RE = re.compile(r'<(IconButton|ActionButton|ToolbarButton)\b[^>]*/>')
IMG_TAG_RE = re.compile(r'<img\b[^>]*>', re.IGNORECASE)
CLICKABLE_DIV_RE = re.compile(r'<(div|span)\b[^>]*\bonClick\b[^>]*>')
ARIA_LABEL_RE = re.compile(r'aria-label(?:ledby)?\s*=')
KEY_HANDLER_RE = re.compile(r'\bonKey(?:Down|Press|Up)\b')
IMPORT_LINE_RE = re.compile(r'^\s*(?:import\b.*|export\s+\*?\s*(?:\{[^}]*\})?\s*from\b.*|(?:const|let|var)\s+.*=\s*require\(.*)$', re.MULTILINE)


@dataclass
class Violation:
    guideline: str
    severity: str  # critical, warning, info
    rule: str
    message: str
    file: str
    line: Optional[int] = None
    suggestion: Optional[str] = None


@dataclass
class CheckResult:
    guideline: str
    passed: bool
    violations: list = field(default_factory=list)
    files_checked: int = 0


def line_of(content: str, index: int) -> int:
    """1-based line number for a character offset."""
    return content.count('\n', 0, index) + 1


def without_imports(content: str) -> str:
    """Blank out import/require lines, preserving offsets so line numbers stay valid.

    Ordering checks must look at rendered markup, not at the order names happen to
    appear in an import statement.
    """
    return IMPORT_LINE_RE.sub(lambda m: ' ' * len(m.group(0)), content)


class GuidelineChecker:
    """Base class for guideline-specific checkers."""

    def __init__(self):
        self.violations = []

    def check_file(self, filepath: str, content: str) -> list[Violation]:
        raise NotImplementedError


class AppHeaderChecker(GuidelineChecker):
    """Check app header / top app bar guideline compliance (appheader.md)."""

    def check_file(self, filepath: str, content: str) -> list[Violation]:
        violations = []

        header_match = APP_HEADER_RE.search(content)
        if not header_match:
            return violations

        header_line = line_of(content, header_match.start())

        # A help entry point is mandatory (WCAG 2.2 SC 3.2.6 Consistent Help).
        if not HELP_ENTRY_RE.search(content):
            violations.append(Violation(
                guideline='appheader',
                severity='critical',
                rule='Help entry point is mandatory',
                message='App header found but no help entry point is present',
                file=filepath,
                line=header_line,
                suggestion='Add a help menu to the app header, in the same position on every page'
            ))

        # App-level menus should be grouped, not scattered across the bar.
        if not HEADER_MENUS_RE.search(content):
            violations.append(Violation(
                guideline='appheader',
                severity='warning',
                rule='App-level menus are grouped at the trailing edge',
                message='App header found but no grouped menu/action container is present',
                file=filepath,
                line=header_line,
                suggestion='Group settings and help in the header menu container at the trailing edge'
            ))

        # Order: settings inboard of help, i.e. settings appears before help.
        # Compare positions in the markup only — an import statement lists names
        # in an order that says nothing about render order.
        markup = without_imports(content)
        settings_match = SETTINGS_ENTRY_RE.search(markup)
        help_match = HELP_ENTRY_RE.search(markup)
        if settings_match and help_match and settings_match.start() > help_match.start():
            violations.append(Violation(
                guideline='appheader',
                severity='warning',
                rule='Menu order: settings inboard of help',
                message='Settings entry point appears after the help entry point',
                file=filepath,
                line=line_of(markup, settings_match.start()),
                suggestion='Order trailing-edge menus as: settings, then help (help outermost)'
            ))

        return violations


class DataTableChecker(GuidelineChecker):
    """Check data table guideline compliance (datatable.md)."""

    def check_file(self, filepath: str, content: str) -> list[Violation]:
        violations = []

        table_match = DATA_TABLE_RE.search(content)
        if not table_match:
            return violations

        table_line = line_of(content, table_match.start())

        if not LOADING_RE.search(content):
            violations.append(Violation(
                guideline='datatable',
                severity='warning',
                rule='Explicit loading state required',
                message='Data table found with no visible loading state handling',
                file=filepath,
                line=table_line,
                suggestion='Render skeleton rows or a progress indicator while rows are loading'
            ))

        if not EMPTY_STATE_RE.search(content):
            violations.append(Violation(
                guideline='datatable',
                severity='warning',
                rule='Explicit empty state required',
                message='Data table found with no empty state handling',
                file=filepath,
                line=table_line,
                suggestion='Add an empty state, distinguishing "no results" from "no data yet"'
            ))

        if SORT_RE.search(content) and not ARIA_SORT_RE.search(content):
            violations.append(Violation(
                guideline='datatable',
                severity='warning',
                rule='Sort state must be exposed to assistive technology',
                message='Sorting is implemented but no aria-sort attribute was found',
                file=filepath,
                line=table_line,
                suggestion='Set aria-sort on the sorted column header (ascending/descending/none)'
            ))

        return violations


class FilterFieldChecker(GuidelineChecker):
    """Check filter field guideline compliance (filterfield.md)."""

    def check_file(self, filepath: str, content: str) -> list[Violation]:
        violations = []

        advanced_match = ADVANCED_FILTER_RE.search(content)
        if not advanced_match:
            return violations

        filter_line = line_of(content, advanced_match.start())

        simple_match = SIMPLE_FILTER_RE.search(content)
        if simple_match:
            violations.append(Violation(
                guideline='filterfield',
                severity='critical',
                rule='One filtering control per dataset',
                message='An advanced filter field and a simple filter bar appear in the same file',
                file=filepath,
                line=filter_line,
                suggestion='Scope a dataset with either an expression filter field or a faceted '
                           'filter bar, never both'
            ))

        if not DEBOUNCE_RE.search(content):
            violations.append(Violation(
                guideline='filterfield',
                severity='warning',
                rule='Debounce suggestion requests (300 ms minimum)',
                message='Filter field found with no debounce or throttle on the suggestion callback',
                file=filepath,
                line=filter_line,
                suggestion='Wait at least 300 ms after the last keystroke before fetching suggestions'
            ))

        if not ABORT_RE.search(content):
            violations.append(Violation(
                guideline='filterfield',
                severity='info',
                rule='Cancel superseded suggestion requests',
                message='Filter field found with no request cancellation',
                file=filepath,
                line=filter_line,
                suggestion='Use AbortController so a slow early response cannot overwrite a later one'
            ))

        return violations


class AccessibilityChecker(GuidelineChecker):
    """Check WCAG 2.2 AA guideline compliance (accessibility.md)."""

    def check_file(self, filepath: str, content: str) -> list[Violation]:
        violations = []

        # SC 1.1.1 Non-text Content: every <img> needs an alt attribute
        # (alt="" for decorative images).
        for match in IMG_TAG_RE.finditer(content):
            if 'alt=' not in match.group(0):
                violations.append(Violation(
                    guideline='accessibility',
                    severity='critical',
                    rule='Images require an alt attribute (WCAG 2.2 SC 1.1.1)',
                    message='Found <img> with no alt attribute',
                    file=filepath,
                    line=line_of(content, match.start()),
                    suggestion='Add alt="..." for informative images, alt="" for decorative ones'
                ))
                break  # report once per file

        # SC 4.1.2 Name, Role, Value: icon-only controls need an accessible name.
        for pattern in (ICON_ONLY_BUTTON_RE, SELF_CLOSING_ICON_BUTTON_RE):
            for match in pattern.finditer(content):
                if not ARIA_LABEL_RE.search(match.group(0)):
                    violations.append(Violation(
                        guideline='accessibility',
                        severity='critical',
                        rule='Icon-only controls need an accessible name (WCAG 2.2 SC 4.1.2)',
                        message='Found an icon-only control with no aria-label or aria-labelledby',
                        file=filepath,
                        line=line_of(content, match.start()),
                        suggestion='Add aria-label matching the tooltip text, and mark the icon '
                                   'aria-hidden="true"'
                    ))
                    break

        # SC 2.1.1 Keyboard: a click handler on a non-interactive element needs
        # a role, a tab stop, and key handling.
        for match in CLICKABLE_DIV_RE.finditer(content):
            tag = match.group(0)
            if 'role=' not in tag or 'tabIndex' not in tag:
                violations.append(Violation(
                    guideline='accessibility',
                    severity='critical',
                    rule='Click targets must be keyboard operable (WCAG 2.2 SC 2.1.1)',
                    message='Found onClick on a <div>/<span> without both role and tabIndex',
                    file=filepath,
                    line=line_of(content, match.start()),
                    suggestion='Use a <button>, or add role, tabIndex, and a key handler'
                ))
                break

        onclick_count = len(re.findall(r'\bonClick\b', content))
        if onclick_count > 0 and not KEY_HANDLER_RE.search(content):
            violations.append(Violation(
                guideline='accessibility',
                severity='info',
                rule='Keyboard handlers for custom interactive elements',
                message='Found onClick handlers but no keyboard event handlers in this file',
                file=filepath,
                suggestion='Native buttons and links need no key handler; custom widgets do'
            ))

        return violations


class TerminologyChecker(GuidelineChecker):
    """Check alert/notification terminology (alerting-terminology.md)."""

    ACTION_WITH_NOTIFICATION = re.compile(
        r'["\'][^"\']*(?:action required|requires action|must respond|respond immediately|'
        r'immediate|urgent|acknowledge)[^"\']*notification[^"\']*["\']',
        re.IGNORECASE
    )
    NOTIFICATION_WITH_ACTION = re.compile(
        r'["\'][^"\']*notification[^"\']*(?:action required|requires action|must respond|'
        r'acknowledge now)[^"\']*["\']',
        re.IGNORECASE
    )
    ALERT_WITHOUT_ACTION = re.compile(
        r'["\'][^"\']*(?:no action (?:is )?(?:required|needed)|informational only|'
        r'for your information)[^"\']*alert[^"\']*["\']',
        re.IGNORECASE
    )

    def check_file(self, filepath: str, content: str) -> list[Violation]:
        violations = []

        for pattern in (self.ACTION_WITH_NOTIFICATION, self.NOTIFICATION_WITH_ACTION):
            match = pattern.search(content)
            if match:
                violations.append(Violation(
                    guideline='alerting-terminology',
                    severity='warning',
                    rule='Use "alert" when timely action is required',
                    message='Found "notification" in a string that also demands user action',
                    file=filepath,
                    line=line_of(content, match.start()),
                    suggestion='If the user must act in time, the term is "alert", not "notification"'
                ))
                break

        match = self.ALERT_WITHOUT_ACTION.search(content)
        if match:
            violations.append(Violation(
                guideline='alerting-terminology',
                severity='warning',
                rule='Use "notification" when no timely action is required',
                message='Found "alert" in a string that states no action is required',
                file=filepath,
                line=line_of(content, match.start()),
                suggestion='If no timely response is implied, the term is "notification", not "alert"'
            ))

        return violations


class SettingsChecker(GuidelineChecker):
    """Check settings guideline compliance (settings.md)."""

    def check_file(self, filepath: str, content: str) -> list[Violation]:
        violations = []

        name = filepath.lower()
        if 'schema' not in name and 'setting' not in name and 'preference' not in name:
            return violations

        if '"type"' in content or "'type'" in content:
            if '"description"' not in content and "'description'" not in content:
                violations.append(Violation(
                    guideline='settings',
                    severity='warning',
                    rule='Settings fields carry descriptions',
                    message='Settings schema appears to be missing description fields',
                    file=filepath,
                    suggestion='Describe what each setting controls and who it affects'
                ))

        if '"title"' in content or "'title'" in content:
            if '"displayName"' not in content and '"label"' not in content \
                    and "'label'" not in content and '"title"' not in content:
                violations.append(Violation(
                    guideline='settings',
                    severity='info',
                    rule='Settings fields carry visible labels',
                    message='Settings schema may be missing user-visible field labels',
                    file=filepath,
                    suggestion='Every field needs a visible, persistent, translatable label'
                ))

        return violations


CHECKERS = {
    'appheader': AppHeaderChecker,
    'datatable': DataTableChecker,
    'filterfield': FilterFieldChecker,
    'accessibility': AccessibilityChecker,
    'alerting-terminology': TerminologyChecker,
    'settings': SettingsChecker,
}


def get_checkers(guideline: Optional[str] = None) -> list[GuidelineChecker]:
    """Get checkers to run based on guideline filter."""
    if guideline:
        if guideline not in CHECKERS:
            print(f"Unknown guideline: {guideline}")
            print(f"Available: {', '.join(CHECKERS)}")
            sys.exit(1)
        return [CHECKERS[guideline]()]

    return [cls() for cls in CHECKERS.values()]


def scan_directory(path: str, checkers: list[GuidelineChecker]) -> list[Violation]:
    """Scan directory for violations."""
    violations = []
    extensions = {'.ts', '.tsx', '.js', '.jsx', '.json', '.vue', '.svelte', '.html'}
    skip_dirs = {'node_modules', 'dist', 'build', '.next', 'coverage', 'vendor', '__snapshots__'}

    path_obj = Path(path)

    if path_obj.is_file():
        files = [path_obj]
    else:
        files = [f for f in path_obj.rglob('*') if f.suffix in extensions]

    for filepath in files:
        if skip_dirs.intersection(filepath.parts):
            continue

        try:
            content = filepath.read_text(encoding='utf-8')
        except Exception as e:
            print(f"Warning: Could not read {filepath}: {e}", file=sys.stderr)
            continue

        for checker in checkers:
            violations.extend(checker.check_file(str(filepath), content))

    return violations


def format_violations(violations: list[Violation], output_format: str) -> str:
    """Format violations for output."""
    if output_format == 'json':
        return json.dumps([asdict(v) for v in violations], indent=2)

    if not violations:
        return "No violations found."

    lines = [f"Found {len(violations)} violation(s):\n"]

    critical = [v for v in violations if v.severity == 'critical']
    warning = [v for v in violations if v.severity == 'warning']
    info = [v for v in violations if v.severity == 'info']

    for severity, group in [('CRITICAL', critical), ('WARNING', warning), ('INFO', info)]:
        if group:
            lines.append(f"\n## {severity} ({len(group)})\n")
            for v in group:
                lines.append(f"- [{v.guideline}] {v.message}")
                location = v.file if v.line is None else f"{v.file}:{v.line}"
                lines.append(f"  File: {location}")
                lines.append(f"  Rule: {v.rule}")
                if v.suggestion:
                    lines.append(f"  Fix: {v.suggestion}")
                lines.append("")

    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(
        description='Check front-end code against the UI guideline reference files.'
    )
    parser.add_argument('path', nargs='?', help='File or directory to check')
    parser.add_argument('--guideline', '-g', choices=sorted(CHECKERS),
                        help='Check a single guideline only')
    parser.add_argument('--output', '-o', choices=['text', 'json'], default='text',
                        help='Output format (default: text)')
    parser.add_argument('--list', '-l', action='store_true',
                        help='List the available guideline checks and exit')
    args = parser.parse_args()

    if args.list:
        for name, cls in sorted(CHECKERS.items()):
            summary = (cls.__doc__ or '').strip().splitlines()[0]
            print(f"{name:22} {summary}")
        sys.exit(0)

    if not args.path:
        parser.error('the following arguments are required: path (or use --list)')

    if not os.path.exists(args.path):
        print(f"Error: Path not found: {args.path}")
        sys.exit(1)

    checkers = get_checkers(args.guideline)
    violations = scan_directory(args.path, checkers)

    print(format_violations(violations, args.output))

    # Exit with an error code if critical violations were found.
    critical_count = sum(1 for v in violations if v.severity == 'critical')
    sys.exit(1 if critical_count > 0 else 0)


if __name__ == '__main__':
    main()
