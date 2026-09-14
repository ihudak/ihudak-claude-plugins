# Green: an unclosed fence at the end of the file is still a diagram

The fence below is never closed. CommonMark runs it to the end of the file, GitHub draws what it holds, and what it holds is a valid diagram.

```mermaid
flowchart TD
    a --> b
