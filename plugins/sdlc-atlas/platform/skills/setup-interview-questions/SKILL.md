---
name: setup-interview-questions
description: >-
  Single source of truth for every question batch in the pipeline.
  All agents pull from here verbatim — no ad-hoc question generation.
  Three greenfield batches, one architecture batch, one spec batch.
scope: platform
---

# Pipeline Question Bank

Every question in the pipeline lives here. Agents load this skill and use the
batch verbatim — never invent new questions, never rephrase.

**Answer style rule:** Tell the developer answers should be short — pick a letter,
type a word, or write one sentence. No essays needed.

---

## BATCH 1 — Project basics (asked by /start, 4 questions)

Send this as one message. Wait for one reply. Fast — should take < 1 min.

```
[start] ▸ Step 1 of 5 — Project basics

Answer short — a word or one sentence is enough. Type "skip" to decide later.

Q1. Project folder path?
    (full path, e.g. C:\Users\you\projects\my-app)

Q2. Project name?

Q3. What does it do?
    (one sentence)

Q4. Type?
    a) Web app (frontend + backend + DB)
    b) API only
    c) Frontend only
    d) CLI / script
    e) Mobile app
    f) Other
```

---

## BATCH 2 — Stack + profile (asked by /start, 2 questions)

Send after batch 1 answers received. One message, wait for one reply.

```
[start] ▸ Step 2 of 5 — Stack & profile

Q5. Stack? (pick one letter per row — or type your own)

    Backend:   a) FastAPI  b) Django  c) Express  d) NestJS  e) Go/Gin  f) None
    Frontend:  a) React    b) Next.js c) Angular  d) Vue     e) Svelte  f) None
    Database:  a) Postgres b) MySQL   c) MongoDB  d) SQLite  e) Redis   f) None
    Extras:    a) Celery   b) Docker  c) S3       d) Clerk/Auth0  e) Stripe  f) None

Q6. Pipeline profile?
    a) small      — spec + build + 3 gates (solo / prototype)
    b) standard   — + requirements + code review (recommended)
    c) enterprise — all phases + ADRs + compliance
```

---

## BATCH 3 — Gates + team (asked by /start, 4 questions)

Send after batch 2 answers received. One message, wait for one reply.
All skippable — user can type "skip" for any.

```
[start] ▸ Step 3 of 5 — Quality gates & team

Q7. Test command?
    a) pytest --cov=app --cov-report=term-missing
    b) npm test -- --watchAll=false
    c) go test ./...
    d) skip

Q8. Security scan?
    a) npm audit / pip-audit (dependency scan)
    b) bandit / semgrep (SAST)
    c) gitleaks (secret scan)
    d) trivy (container scan)
    e) skip

Q9. Lint command?
    a) ruff check .
    b) npx eslint . && npx tsc --noEmit
    c) golangci-lint run
    d) skip

Q10. Tech leads? (GitHub/Slack handles — skip if solo)
```

---

## BATCH 4 — Architecture questions (reference only — architecture-agent embeds these one-at-a-time)

These are the canonical architecture questions. Architecture-agent uses Mode B (one-at-a-time)
and sends them individually from its own body — NOT as a batch from this skill.
This section is a reference list so the question set is defined in one place.
Do NOT send this batch as a single message.

```
[architecture-agent] ▸ Step 4 of 5 — System architecture

Quick answers — pick a letter or type a word. "skip" = decide later.

Q1. Database?
    a) PostgreSQL  b) MySQL  c) MongoDB  d) SQLite  e) Redis  f) None  g) skip

Q2. Auth?
    a) None for now  b) JWT (self-managed)  c) OAuth (e.g. Google)
    d) Auth provider (Clerk / Auth0)  e) Session-based  f) skip

Q3. API style?
    a) REST  b) GraphQL  c) tRPC  d) skip

Q4. Repo layout?
    a) Single repo (all in one)  b) Monorepo (separate frontend/backend folders)

Q5. Expected scale?
    a) Prototype / personal  b) Small team (< 20 users)
    c) Product (hundreds)   d) High traffic (thousands+)

Q6. Deployment target?
    a) Vercel / Netlify   b) AWS / GCP / Azure  c) Railway / Render
    d) Docker / self-hosted  e) skip

Q7. Observability?
    a) None for now  b) Sentry (errors)  c) Datadog / New Relic
    d) OpenTelemetry  e) skip

Q8. External services needed now?
    (type names, e.g. "Stripe, SendGrid" — or "none")

Q9. Hard constraints?
    (compliance, latency limits, data residency — or "none")
```

---

## BATCH 5 — Feature clarification (asked by spec-agent, per-feature)

Send as ONE message at spec interview start. Include only genuine ambiguities —
cross out anything already answered in requirements or feature description.

```
[spec-agent] ▸ Step 5 of 5 — Feature clarification

Quick answers only. Skip anything already decided.

Q1. Who can access this? (auth / role requirement)
Q2. Data scope? a) Per-user  b) Per-org  c) Global
Q3. What happens if <dependency> is down? a) Error shown  b) Queue & retry  c) Skip
Q4. Can this operation be retried safely? a) Yes  b) No  c) Not applicable
Q5. Pagination needed on list views? a) Yes  b) No
```

Only include questions where the answer changes the code. Omit any already answered.
Max 5 questions — if you have more, pick the 5 most consequential.

---

## Brownfield confirmation (audit-project only)

Used by setup-agent after deep read. ONE message — fill in detected values.

```
[setup-agent] ▸ Here's what I found — confirm or correct

Project: <name>     Type: <type>     Stack: <detected>

Detected commands:
  test:     <cmd or "not detected">
  security: <cmd or "not detected">
  lint:     <cmd or "not detected">

Q1.  Name correct? [<detected>]
Q2.  One-sentence description?
Q3.  Type correct? a) Web app  b) API  c) Frontend  d) CLI  e) Mobile  f) Other
Q4.  Stack correct? Any layer missing? [<detected>]
Q5.  Profile?  a) small  b) standard  c) enterprise
Q6.  Test command? [<detected>]  (skip = decide later)
Q7.  Security scan? [<detected>]  (skip = decide later)
Q8.  Lint command? [<detected>]  (skip = decide later)
Q9.  Work item tracker?  a) Jira  b) Azure DevOps  c) GitHub Issues  d) Linear  e) None
Q10. Protected branches? [main]  (skip = keep)
Q11. Gap resolution?  a) interactive  b) autonomous
Q12. Tech leads? (skip if solo)
Q13. [enterprise] Org policy: repo URL, branch, file path?  (skip = decide later)
Q14. Anything built I missed?
```

---

## Rules

- **Never ask questions outside this bank.** File `/propose` if a new question is needed.
- **One batch per message** — never ask individual questions one at a time.
- **Parallel writes** — after receiving a batch reply, write ALL files simultaneously, not sequentially.
- **Skip = none** — record `none` in the field, never guess a default.
- **Batch 1–3 sent by orchestrator/setup-agent (Mode A).** Batch 4 is a reference only — architecture-agent sends these one-at-a-time (Mode B) from its own body. Batch 5 by spec-agent (Mode B, composed per-feature from genuine ambiguities).
- **Context bundle** — after each batch, append answers to `memory/context_bundle.md`. Downstream agents read this and never re-ask.
