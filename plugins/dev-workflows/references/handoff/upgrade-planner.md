# upgrade-planner Handoff Format

## Input (orchestrator → upgrade-planner)

```markdown
## Upgrade Plan Request
repo: /absolute/path/to/repo
component: spring-boot
target: latest             # exact version | minor | latest | lts | (bare = latest compatible)
other_upgrades:            # other components being upgraded in the SAME command
  - name: java
    target: 21
repo_inventory:            # snapshot of key version info from build files
  java: "17"
  spring-boot: "3.1.4"
  hibernate: "6.2.0"
  gradle: "8.4"
model_routing:             # optional; echoed back in output. See `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md` for the model-routing block schema
  classification: SIGNIFICANT
```

## Output (upgrade-planner → orchestrator / upgrade-executor)

```markdown
## Upgrade Plan: spring-boot
status: READY              # READY | CONFLICT | NOT_FOUND
component: spring-boot
ecosystem: Maven
from: "3.1.4"
to: "3.3.11"
files:
  - path: pom.xml
    change: "bump spring-boot-starter-parent from 3.1.4 to 3.3.11"
related:
  - component: hibernate
    from: "6.2.0"
    to: "6.4.0"
    required: true
    reason: "Spring Boot 3.3 requires Hibernate 6.4+"
conflict_details: null     # populated only when status: CONFLICT
alternatives:              # populated only when status: CONFLICT, ranked least-invasive first
  - description: "Use spring-boot 3.2.12 (compatible with Java 17)"
    tokens: [{component: spring-boot, to: "3.2.12"}]
  - description: "Upgrade Java to 21 first, then spring-boot 3.3.11 is compatible"
    tokens: [{component: java, to: "21"}, {component: spring-boot, to: "3.3.11"}]
```

**status values:**
- `READY` — plan is conflict-free; safe to hand off to upgrade-executor
- `CONFLICT` — incompatibility detected; orchestrator must surface alternatives to user
- `NOT_FOUND` — component not detected in repo; orchestrator should warn and skip
