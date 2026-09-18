# Red: the reported line holds when a comment sits directly above the failure

```mermaid
flowchart TD
    a["x"]
    %% a comment directly above the broken edge
    a -->|see [BR#n]| b
```
