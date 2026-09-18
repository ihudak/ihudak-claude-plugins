# Red: a diagram after a line that opens with a code span

```` ```mermaid ```` opens a diagram; this line is prose, not a fence, because a backtick fence's info string may not contain a backtick.

```mermaid
flowchart TD
    a["x"]
    b["y"]
    a -->|see [BR#n]| b
```
