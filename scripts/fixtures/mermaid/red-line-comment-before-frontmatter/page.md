# Red: the reported line holds past a comment before frontmatter

```mermaid
%% a comment above the frontmatter, which mermaid only strips on its second pass
---
title: Frontmatter after a comment
---
flowchart TD
    a["x"]
    b["y"]
    a -->|see [BR#n]| b
```
