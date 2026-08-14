---
name: diagram-generation
description: >-
  Guidelines for generating visual layouts, sequencing flows, and diagrams
  using Mermaid or Excalidraw-JSON formats.
scope: platform
requirement: DIAGRAM_GENERATION
---

# Diagram Generation Guidelines

**Standardizing vector layouts and system architecture visual representations.**

## 1. Flowcharts & Architecture Layouts
Use standard Mermaid definitions for architectural components:
- Use clear node labels without special characters to avoid parsing errors.
- Group related components (e.g., API Gateway, Services, Databases) using `subgraph` boxes.
- Always specify layouts: `graph TD` (Top-Down) or `graph LR` (Left-to-Right).

## 2. Sequence Diagrams
For event-driven interactions and API request/response flows:
- Define distinct participants clearly (`actor User`, `participant API`, `participant Database`).
- Use arrow types correctly: `->>` for synchronous calls, `-->>` for responses, and `->` for asynchronous messages.
- Include failure and retry loops inside `alt`/`else` or `loop` statements.

## 3. Database Entity Relationship (ER) Diagrams
For schema designs and database migrations:
- Use `erDiagram` syntax.
- List table entities, keys (`PK`, `FK`), and attribute types (`varchar`, `int`, etc.).
- Use standard cardinality symbols (e.g., `||--o{` for one-to-many relationship).

## 4. Compilation
When `/render-diagram` is run:
- Compile the syntax.
- Verify that the rendered SVG/PNG contains all node boxes and arrow lines.
- Ensure that diagram image paths in Markdown specs use relative URLs (`./images/my-diagram.svg`) to render correctly during spec compilation.
