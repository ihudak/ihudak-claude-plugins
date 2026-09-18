# Red: the reported line holds past whole-line comments

```mermaid
flowchart TD
    %% a comment, which mermaid removes before it counts lines
    a["x"]
    %% another
    b["y"]

    a -->|see [BR#n]| b
```
