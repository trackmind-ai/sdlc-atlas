---
name: coverage-report
description: >
  Estimates feature-level test coverage using test discovery and
  feature-to-test mapping heuristics. Produces coverage classifications
  and reports for audited repositories.
version: 1.0.0
category: platform
---

# Coverage Report Skill

## Purpose

Estimate whether discovered features appear sufficiently tested.

This skill:

- Discovers test files
- Maps tests to feature key files
- Estimates feature coverage
- Classifies testing adequacy
- Produces human-readable coverage reports

This is an estimation mechanism.

It is NOT a replacement for runtime coverage tools.

---

# Responsibilities

This skill owns:

- Test discovery
- Test exclusion filters
- Feature-to-test mapping
- Coverage estimation
- Threshold classification
- Terminal coverage tables
- Coverage report generation
- Greenfield skip logic

This skill DOES NOT own:

- Executing tests
- Line coverage instrumentation
- Mutation testing
- CI execution
- Test generation

---

# Inputs

Required:

```yaml
built_features:
    - feature_name
    - key_files

repository_root: .
```

---

# Greenfield Skip

## Purpose

Avoid generating meaningless reports when no features exist.

---

## Condition

Built features section is empty:

```text
§ Built Features

None
```

or

```yaml
built_features: []
```

---

## Behavior

Skip coverage analysis entirely.

Print:

```text
Coverage report skipped.

Reason:
No built features detected.
```

---

## Output

No report file shall be written.

---

# Test File Discovery

## Purpose

Identify repository test files.

---

# Supported Patterns

## Python

```text
*test*.py
tests/**/*.py
test_*.py
*_test.py
```

---

## Java

```text
*Test.java
*Tests.java
*IT.java
```

---

## JavaScript / TypeScript

```text
__tests__/**/*
tests/**/*
*.test.js
*.test.jsx
*.test.ts
*.test.tsx
*.spec.js
*.spec.ts
*.spec.tsx
```

---

## C#

```text
*Tests.cs
*Test.cs
```

---

## Go

```text
*_test.go
```

---

## Ruby

```text
*_spec.rb
spec/**/*
```

---

## PHP

```text
*Test.php
tests/**/*
```

---

## Generic

```text
tests/**/*
__tests__/**/*
```

---

# Exclusion Directories

Always exclude:

```text
node_modules/
.git/
__pycache__/
dist/
build/
.next/
venv/
.venv/
```

---

## Exclusion Rule

If a path begins with an excluded directory:

```text
SKIP
```

Never treat excluded files as tests.

---

# Test Discovery Workflow

```text
Enumerate Files
↓
Apply Exclusion Filters
↓
Match Test Patterns
↓
Collect Test Files
```

---

# Feature-to-Test Mapping

## Purpose

Estimate which tests validate which features.

---

# Inputs

Feature:

```yaml
feature:
    name: Authentication
    key_files:
        - src/auth/service.py
        - src/auth/routes.py
```

Test file:

```text
tests/test_auth_service.py
```

---

# Mapping Strategy

Read test file contents.

Search for references to feature key files.

---

## Match Types

A test maps to a feature if it contains:

### Import Paths

Example:

```python
from src.auth.service import login
```

Matches:

```text
src/auth/service.py
```

---

### Relative Imports

Example:

```javascript
import AuthService from "../../src/auth/service"
```

Matches:

```text
src/auth/service
```

---

### Package References

Example:

```java
import com.example.auth.AuthService;
```

Matches:

```text
auth/AuthService.java
```

---

### Literal References

Example:

```text
"src/auth/routes.py"
```

Matches directly.

---

# Mapping Rules

A test file counts once per key file.

Example:

```yaml
Feature:
    key_files:
        - auth.py
        - routes.py

Test:
    references auth.py twice
```

Counts as:

```yaml
auth.py: covered
routes.py: uncovered
```

---

# Coverage Estimation Formula

Coverage is estimated using:

```text
(test files mapped to feature key files
 /
 total key files in feature)
× 100
```

---

# Definitions

Numerator:

```text
Number of unique key files
referenced by at least one test.
```

Denominator:

```text
Total key files in feature.
```

---

# Example

Feature:

```yaml
key_files:
    - auth.py
    - routes.py
    - tokens.py
    - middleware.py
```

Mapped:

```yaml
auth.py
tokens.py
middleware.py
```

Coverage:

```text
(3 / 4) × 100

= 75.0%
```

---

# Coverage Classification

## UNDER-TESTED

Condition:

```text
coverage < 80%
```

Status:

```text
UNDER-TESTED
```

---

## OK

Condition:

```text
coverage ≥ 80%
```

Status:

```text
OK
```

---

# Classification Examples

```text
79.9% → UNDER-TESTED
80.0% → OK
95.2% → OK
12.5% → UNDER-TESTED
```

---

# Terminal Table Format

## Purpose

Provide concise audit output.

---

# Format

```text
Feature              | Coverage | Status
------------------------------------------------
Payments             | 25.0%    | UNDER-TESTED
Notifications        | 66.7%    | UNDER-TESTED
Authentication       | 80.0%    | OK
Reporting            | 100.0%   | OK
```

---

# Sorting Rules

Sort by:

```text
Coverage ascending
```

Lowest coverage first.

---

# Formatting Rules

Coverage:

```text
One decimal place
```

Examples:

```text
25.0%
66.7%
80.0%
100.0%
```

---

# Coverage Report File

## Purpose

Persist detailed coverage results.

---

# Default Path

```text
.claude/memory/coverage_report.md
```

---

# Report Structure

## Timestamp

Example:

```markdown
# Coverage Report

Generated:
2026-06-22T15:45:00Z
```

---

## Summary Statistics

Example:

```markdown
## Summary

Total Features: 8

OK: 5

UNDER-TESTED: 3

Average Coverage: 78.4%
```

---

## Terminal Summary Table

Example:

```markdown
| Feature | Coverage | Status |
|-----------|-----------|----------|
| Payments | 25.0% | UNDER-TESTED |
| Authentication | 80.0% | OK |
```

Sorted ascending by coverage.

---

# Per-Feature Sections

Format:

```markdown
## Authentication

Coverage:
80.0%

Status:
OK

### Test Files

- tests/test_auth_service.py
- tests/test_routes.py

### Key Files

- src/auth/service.py
- src/auth/routes.py
```

---

# Example Feature Section

```markdown
## Payments

Coverage:
50.0%

Status:
UNDER-TESTED

### Test Files

- tests/test_payment_service.py

### Key Files

- src/payments/service.py
- src/payments/routes.py
```

---

# Report Generation Workflow

```text
Load Built Features
↓
Greenfield Check
↓
Discover Tests
↓
Map Tests to Features
↓
Calculate Coverage
↓
Classify Status
↓
Sort Results
↓
Print Terminal Table
↓
Write Coverage Report
```

---

# Terminal Output Example

```text
Feature              | Coverage | Status
------------------------------------------------
Payments             | 25.0%    | UNDER-TESTED
Notifications        | 66.7%    | UNDER-TESTED
Authentication       | 80.0%    | OK
Reporting            | 100.0%   | OK
```

---

# Failure Handling

No tests discovered:

```yaml
status: warning

reason: no_tests_found
```

Coverage becomes:

```text
0.0%
UNDER-TESTED
```

---

Feature missing key files:

```yaml
status: warning

reason: feature_has_no_key_files
```

Skip that feature.

---

Report write failure:

```yaml
status: error

reason: coverage_report_write_failed
```

Do not partially write reports.

---

# Agent Usage

Invoke this skill after feature discovery during
`/audit-project` workflows.

Use it to estimate testing adequacy for discovered
features and surface potentially under-tested areas.

This skill is the single source of truth for
coverage estimation and reporting across the
sdlc-atlas platform.