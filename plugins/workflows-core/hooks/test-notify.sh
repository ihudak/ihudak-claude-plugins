#!/usr/bin/env bash
# Fires after every Bash tool call. Detects test suite commands, parses results, notifies.
# Always exits 0 — must never block Claude.

# Guard: if python3 is not available, skip silently
command -v python3 &>/dev/null || exit 0

input=$(cat)

command=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Claude Code's PostToolUse payload nests these under tool_input / tool_response.
    # Fall back to top-level keys for older versions or non-standard runners.
    cmd = (d.get('tool_input') or {}).get('command', '') or d.get('command', '')
    print(cmd)
except Exception:
    print('')
" 2>/dev/null) || true

output=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    out = (d.get('tool_response') or {}).get('output', '') or d.get('output', '')
    print(out)
except Exception:
    print('')
" 2>/dev/null) || true

# Exit early if this wasn't a test command
if ! echo "$command" | grep -qE '(mvn test|gradlew test|gradle test|npm test|yarn test|pytest|make test)'; then
    exit 0
fi

# Parse result using python3 (portable — no grep -P)
# $output is piped via stdin to avoid ARG_MAX limits on large test outputs.
# The parser program therefore CANNOT come from a here-document on the same
# command: a here-document and a pipe compete for fd 0 and the here-document
# wins, so `python3 -` would read the program and the parser would see no
# output at all. Capture the program first, pass it with -c, leave fd 0 to the
# pipe. Under -c, sys.argv[1] is still the first argument after the program.
parser=$(cat <<'PYEOF'
import sys, re

cmd = sys.argv[1] if len(sys.argv) > 1 else ""
out = sys.stdin.read()

def first(pattern, text, default="0"):
    m = re.findall(pattern, text)
    return m[-1] if m else default

def sumall(pattern, text, default="0"):
    vals = [int(x) for x in re.findall(pattern, text) if x.isdigit()]
    return str(sum(vals)) if vals else default

if "mvn" in cmd:
    # Surefire prints a "Tests run:" line per test class AND a summary line per
    # module under "Results:". A per-class line continues past "Skipped: N" with
    # a time/class suffix; a summary line ends there — so anchoring at end of
    # line sums modules without counting every class a second time. Where
    # nothing matches that anchored form, fall back to the unanchored counts.
    rows = re.findall(
        r"Tests run: (\d+), Failures: (\d+), Errors: (\d+), Skipped: \d+[ \t]*\r?$",
        out, re.M)
    if rows:
        total = str(sum(int(r[0]) for r in rows))
        failures = str(sum(int(r[1]) for r in rows))
        errors = str(sum(int(r[2]) for r in rows))
    else:
        total = sumall(r"Tests run: (\d+)", out)
        failures = sumall(r"Failures: (\d+)", out)
        errors = sumall(r"Errors: (\d+)", out)
    print(f"{total} run, {failures} failed, {errors} errors")
elif "gradlew" in cmd or "gradle" in cmd:
    total = first(r"(\d+) tests? completed", out)
    failed = first(r", (\d+) failed", out)
    print(f"{total} completed, {failed} failed")
elif "pytest" in cmd:
    passed = first(r"(\d+) passed", out)
    failed = first(r"(\d+) failed", out)
    print(f"{passed} passed, {failed} failed")
elif "npm" in cmd or "yarn" in cmd:
    passed = first(r"Tests:.*?(\d+) passed", out)
    failed = first(r"Tests:.*?(\d+) failed", out)
    print(f"{passed} passed, {failed} failed")
else:
    print("tests completed")
PYEOF
)

summary=$(printf '%s' "$output" | python3 -c "$parser" "$command" 2>/dev/null) || true

[[ -z "$summary" ]] && summary="tests completed"
message="Test run: $summary"

# Notify using platform-appropriate method
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$message\" with title \"Claude Code\"" 2>/dev/null || true
elif grep -qi microsoft /proc/version 2>/dev/null; then
    wsl-notify-send --category "Claude Code" "$message" 2>/dev/null || \
    powershell.exe -Command \
      "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; \$n = New-Object System.Windows.Forms.NotifyIcon; \$n.Icon = [System.Drawing.SystemIcons]::Information; \$n.Visible = \$true; \$n.ShowBalloonTip(3000, 'Claude Code', '$message', [System.Windows.Forms.ToolTipIcon]::None); Start-Sleep -Milliseconds 3500; \$n.Dispose()" 2>/dev/null || \
    echo -e '\a'
else
    notify-send "Claude Code" "$message" 2>/dev/null || echo -e '\a'
fi

exit 0
