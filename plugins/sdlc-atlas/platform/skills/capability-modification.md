---
name: capability-modification
description: >
  Defines how Claude Code capabilities evolve safely.
  Standardizes command modification, orchestrator step injection,
  agent input/output contracts, runtime context propagation,
  and persisted state boundaries.
version: 1.0.0
category: platform
---

# Capability Modification Skill

## Purpose

Provide a safe and predictable framework for extending existing Claude Code capabilities.

This skill governs:

- Adding new steps to commands
- Modifying orchestrators
- Extending agent contracts
- Passing runtime context
- Persisting long-term state
- Maintaining backward compatibility

Every capability enhancement must follow this skill.

---

# Responsibilities

This skill owns:

- Command evolution guidelines
- Step injection patterns
- Agent contract definitions
- Runtime context rules
- Persisted state boundaries
- Compatibility requirements
- Change validation

This skill DOES NOT own:

- Business logic implementation
- Git execution
- Prompt execution
- Memory storage implementation
- Feature delivery

Those remain the responsibility of the consuming capability.

---

# Core Principles

Capability evolution must be:

1. Additive
2. Explicit
3. Backward compatible
4. Observable
5. Reversible
6. Contract-driven

Avoid hidden dependencies.

Avoid breaking existing consumers.

---

# Capability Layers

Capabilities evolve through layers.

```
User Command
    ↓
Command Orchestrator
    ↓
Agent Chain
    ↓
Platform Skills
    ↓
External Systems
```

Modifications should occur at the lowest layer capable of solving the problem.

---

# Modification Rules

## Allowed

✓ Insert new orchestrator steps

✓ Add optional contract fields

✓ Add runtime context

✓ Introduce new skills

✓ Extend outputs

✓ Add validation stages

✓ Introduce new prompts

---

## Forbidden

✗ Remove required fields

✗ Rename existing fields

✗ Change output meaning

✗ Persist transient runtime values

✗ Introduce hidden dependencies

✗ Modify unrelated contracts

---

# Step Injection

## Purpose

Safely introduce additional behavior into existing commands.

---

## Injection Pattern

Existing:

```text
Step 1
Step 2
Step 3
```

Modified:

```text
Step 1
Injected Step
Step 2
Step 3
```

The original sequence must remain intact.

---

## Requirements

Injected steps must:

- Have a defined purpose
- Produce explicit outputs
- Document downstream consumers
- Fail gracefully
- Preserve prior behavior

---

# Example:
# Adding Branch Selection

Before:

```text
Feature Command

→ spec-agent
→ approval-agent
→ implementation-agent
```

After:

```text
Feature Command

→ branch-selection
→ spec-agent
→ approval-agent
→ implementation-agent
```

---

## Injected Step Contract

Example:

Input:

```yaml
story_id: 1847
```

Output:

```yaml
selected_branch: feature/payments
```

Consumers:

```text
spec-agent
implementation-agent
```

---

# Agent Contracts

## Purpose

Define stable interfaces between agents.

Agents communicate only through contracts.

---

# Input Contract

Example:

```yaml
story_id: string

branch_name: string

runtime_context: object
```

---

# Output Contract

Example:

```yaml
status: success

spec_path: docs/spec.md

branch_name: feature/payments
```

---

# Contract Rules

Required fields:

- Must never change meaning
- Must never be renamed
- Must remain documented

Optional fields:

- May be added
- Must have defaults
- Must be ignored by older consumers

---

# Contract Evolution

Version 1:

```yaml
story_id: string
```

Version 2:

```yaml
story_id: string

branch_name?: string
```

Valid.

---

Version 1:

```yaml
story_id: string
```

Version 2:

```yaml
ticket_id: string
```

Invalid.

Breaking change.

---

# Runtime Context

## Definition

Temporary execution data required during a workflow.

Runtime context exists only during command execution.

---

## Examples

Allowed:

```yaml
selected_branch: develop

approval_decision: approved

retry_attempt: 2

checkout_status: success
```

---

Not Runtime Context:

```yaml
project_knowledge

feature_history

architecture_guidelines
```

Those are persisted artifacts.

---

# Runtime Context Rules

Runtime context:

✓ Flows between steps

✓ May be enriched

✓ May be discarded

✓ Is execution-scoped

Runtime context:

✗ Must not survive execution

✗ Must not be written to memory

✗ Must not alter historical records

---

# Runtime Context Propagation

Initial:

```yaml
story_id: 1847
```

After branch-selection:

```yaml
story_id: 1847

runtime_context:
    selected_branch: feature/payments
```

After spec-agent:

```yaml
story_id: 1847

runtime_context:
    selected_branch: feature/payments

spec_path: docs/spec.md
```

---

# Persisted State

## Definition

Information intentionally retained beyond execution.

---

## Examples

Persisted:

```yaml
knowledge.md

CLAUDE.md

approved-spec.md

feature-history.md
```

---

Not Persisted:

```yaml
retry_attempt

menu_selection

temporary_checkout_result
```

---

# Persisted State Rules

Persist only if information is:

- reusable,
- historically meaningful,
- intentionally durable.

Do not persist operational details.

---

# State Boundary Model

```
Execution Begins
        ↓
Runtime Context Created
        ↓
Runtime Context Enriched
        ↓
Agents Execute
        ↓
Persist Approved Artifacts
        ↓
Runtime Context Destroyed
```

---

# Example:
# Passing Branch Name to Spec Agent

Branch Selection Output:

```yaml
selected_branch: feature/auth
```

Orchestrator Runtime Context:

```yaml
runtime_context:
    selected_branch: feature/auth
```

Spec Agent Input:

```yaml
story_id: 1847

branch_name: feature/auth
```

Spec Agent Output:

```yaml
status: success

spec_path: docs/spec.md
```

---

# Validation Checklist

Before modifying a capability, verify:

- [ ] Existing steps preserved
- [ ] New step documented
- [ ] Inputs documented
- [ ] Outputs documented
- [ ] Contracts backward compatible
- [ ] Runtime values not persisted
- [ ] Persisted artifacts intentional
- [ ] Failure paths defined
- [ ] Consumers identified

---

# Failure Handling

If a modification violates contract rules:

Return:

```yaml
status: rejected

reason: breaking_contract_change
```

Do not deploy the modification.

---

If runtime context attempts persistence:

Return:

```yaml
status: rejected

reason: runtime_context_persistence_violation
```

Reject the change.

---

# Agent Usage

Invoke this skill whenever:

- modifying an existing command,
- inserting new orchestrator behavior,
- extending agent inputs,
- extending agent outputs,
- passing execution state between agents,
- deciding whether information belongs in runtime context or persisted state.

This skill is the single source of truth for capability evolution across the Claude Code platform.