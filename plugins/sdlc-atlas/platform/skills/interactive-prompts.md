---
name: interactive-prompts
description: >
  Standardized human interaction patterns for Claude Code agents.
  Provides numbered selection menus, typed input validation,
  confirmation workflows, retry/cancel behavior, and error prompts.
version: 1.0.0
category: platform
---

# Interactive Prompts Skill

## Purpose

Provide a consistent, predictable, and safe mechanism for agents to
collect information from users.

This skill standardizes:

- Numbered list selection
- Typed input collection
- Input validation
- Confirmation prompts
- Retry workflows
- Cancellation handling
- Error recovery prompts

All agent-to-user interactions must use this skill.

---

# Responsibilities

This skill owns:

- Displaying menus
- Collecting responses
- Validating responses
- Confirming destructive actions
- Handling invalid input
- Retry prompts
- User cancellation
- Returning structured outputs

This skill DOES NOT own:

- Business logic
- Git execution
- Feature implementation
- Pull request creation
- Repository modification

Calling agents remain responsible for those tasks.

---

# Design Principles

Interactions should be:

1. Clear
2. Concise
3. Predictable
4. Recoverable
5. Cancelable
6. Explicit

Users should always understand:

- what is being requested,
- what options exist,
- how to cancel,
- what happens next.

---

# Global Rules

All prompts must:

- Provide explicit instructions.
- Display valid options.
- Explain cancellation.
- Validate responses.
- Limit retries.
- Return structured outcomes.

Never assume intent.

Never infer ambiguous responses.

---

# Retry Policy

Default retry configuration:

```yaml
max_attempts: 3
```

Behavior:

Attempt 1:
    Explain expected input.

Attempt 2:
    Clarify invalid response.

Attempt 3:
    Warn that prompt will cancel.

Exceeded retries:
    Return cancellation.
```

---

# Cancellation Rules

The following inputs are treated as cancellation:

```text
cancel
quit
exit
q
```

Case insensitive.

Examples:

```text
Cancel
CANCEL
q
Exit
```

Return:

```yaml
status: cancelled
reason: user_cancelled
```

Immediately stop interaction.

---

# Numbered List Prompt

## Purpose

Allow users to select from predefined options.

---

## Format

Display:

```text
<Select Prompt>

1. Option One
2. Option Two
3. Option Three

Enter a number (or type 'cancel'):
```

---

## Validation

Accept only:

- integers
- within range

Example:

Options:

```yaml
count: 3
```

Valid:

```text
1
2
3
```

Invalid:

```text
0
4
abc
1.5
yes
```

---

## Success Output

Example:

Input:

```text
2
```

Return:

```yaml
status: success

selection:
    index: 2
    value: Option Two
```

---

## Failure Example

After retries exhausted:

```yaml
status: cancelled
reason: retry_limit_exceeded
```

---

# Typed Input Prompt

## Purpose

Collect free-form user input.

Examples:

- Branch name
- Feature ID
- Ticket number
- Environment name

---

## Format

Display:

```text
<Prompt>

Type your response
(or type 'cancel'):

>
```

---

## Validation Modes

Supported validators:

### Non-empty

Rules:

```yaml
min_length: 1
trim_whitespace: true
```

---

### Regex

Example:

Branch names:

```regex
^[a-zA-Z0-9._/-]+$
```

Ticket IDs:

```regex
^[0-9]+$
```

---

### Length

Example:

```yaml
minimum: 3
maximum: 100
```

---

## Success Output

Example:

Input:

```text
feature/auth-login
```

Return:

```yaml
status: success

value: feature/auth-login
```

---

# Confirmation Prompt

## Purpose

Require explicit approval before continuing.

Used for:

- Branch creation
- Stash restoration
- Potentially destructive operations
- Retrying failed actions

---

## Format

Display:

```text
<Question>

Type:

yes  → continue
no   → cancel

>
```

---

## Accepted Inputs

Continue:

```text
yes
y
```

Cancel:

```text
no
n
cancel
```

Case insensitive.

---

## Success Output

Approval:

```yaml
status: confirmed
approved: true
```

Declined:

```yaml
status: confirmed
approved: false
```

---

# Retry Prompt

## Purpose

Allow users to retry failed operations.

---

## Format

Display:

```text
Operation failed:

<error_message>

Choose:

1. Retry
2. Cancel

Enter choice:
```

---

## Output

Retry:

```yaml
status: retry
```

Cancel:

```yaml
status: cancelled
reason: user_declined_retry
```

---

# Error Recovery Prompt

## Purpose

Present recovery choices when an operation cannot continue automatically.

Examples:

- Branch not found
- Invalid branch
- Missing stash
- Validation failures

---

## Format

Display:

```text
Problem detected:

<description>

Choose:

1. Retry
2. Enter a new value
3. Cancel

Enter choice:
```

---

## Output

Retry:

```yaml
status: retry
```

New Value:

```yaml
status: revise_input
```

Cancel:

```yaml
status: cancelled
reason: user_cancelled
```

---

# Branch Selection Pattern

## Purpose

Used with git-operations skill.

---

## Example

Display:

```text
Select a branch:

1. develop
2. feature/auth
3. release/v2

Enter a number (or type 'cancel'):
```

Input:

```text
2
```

Return:

```yaml
status: success

selection:
    index: 2
    value: feature/auth
```

---

# Branch Creation Confirmation

## Example

Display:

```text
Branch "feature/payment-api" does not exist.

Create it?

Type:

yes → create branch
no  → cancel

>
```

Input:

```text
yes
```

Return:

```yaml
status: confirmed
approved: true
```

---

# Error Retry Example

Display:

```text
Checkout failed:

Branch is currently locked.

Choose:

1. Retry
2. Cancel

Enter choice:
```

Input:

```text
1
```

Return:

```yaml
status: retry
```

---

# Structured Output Contract

Every interaction must return one of:

## Success

```yaml
status: success
```

---

## Confirmation

```yaml
status: confirmed
approved: true|false
```

---

## Retry

```yaml
status: retry
```

---

## Revised Input

```yaml
status: revise_input
```

---

## Cancelled

```yaml
status: cancelled

reason:
    user_cancelled
    retry_limit_exceeded
    user_declined_retry
```

No other status values are permitted.

---

# Agent Usage

Invoke this skill whenever an agent requires user interaction.

Examples:

- Feature Agent:
  Select implementation strategy.

- Git Agent:
  Choose branch to checkout.

- Release Agent:
  Confirm release branch creation.

- Recovery Agent:
  Ask whether failed operations should retry.

This skill is the single source of truth for all interactive behavior across the platform.