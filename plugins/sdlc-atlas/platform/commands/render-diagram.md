---
name: render-diagram
description: >-
  Renders visual design and architectural diagrams from text specifications (Mermaid).
---

# /render-diagram

**Renders visual design and architectural diagrams from text specifications.**

## Invocation

```bash
/render-diagram <source_file> [--output <image_path>] [--format svg|png]
```

## Process

1. Read the input text file (containing Mermaid syntax or architectural layout markup).
2. Render the layout into the target format:
   - Call the local Mermaid CLI renderer (`mmdc`) or a rendering service.
   - For interactive Excalidraw-like wireframes, generate the JSON representation and output it.
3. Save the rendered vector graphic to the specified output path (or default to `.claude/specs/images/<source_filename>.svg`).

## Output

```
✔ Diagram rendered successfully
Rendered file saved to: .claude/specs/images/architecture.svg
```
