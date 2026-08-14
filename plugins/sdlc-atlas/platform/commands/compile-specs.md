---
name: compile-specs
description: >-
  Compiles Markdown specifications, ADRs, and post-mortems into a single release package (PDF/HTML).
---

# /compile-specs

**Compiles Markdown specifications, Architectural Decision Records (ADRs), and post-mortems into a single release package (PDF or HTML).**

## Invocation

```bash
/compile-specs [--format pdf|html] [--output <package_path>]
```

## Process

1. Gather all approved specs under `.claude/specs/` and active ADR files under `docs/adr/`.
2. Sort documents chronologically or by feature dependencies.
3. Parse and compile Markdown files into a single consolidated document structure:
   - Render Mermaid diagrams and local vector graphics inline.
   - Scale screenshots and images to fit pages correctly.
4. Export the compiled release package to the target format (using a local tool like Puppeteer, Pandoc, or Weasyprint).
5. Save to the output path (default: `.claude/memory/releases/release_package_v<version>.<format>`).

## Output

```
✔ Specifications compiled successfully

Consolidated: 5 specs, 3 ADRs
Compiled package saved to: .claude/memory/releases/release_package_v1.0.pdf
```
