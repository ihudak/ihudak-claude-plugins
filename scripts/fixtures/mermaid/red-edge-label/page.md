# Red: an unquoted bracketed edge label

The edge label below carries `[BR#n]` unquoted, which mermaid reads as the start of a node shape. This is the shape that shipped broken on GitHub.

```mermaid
flowchart TD
    a["start"]
    b["end"]
    a -->|claims are its [BR#n] rows| b
```
