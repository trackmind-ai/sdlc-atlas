---
name: queue-agent
description: "BullMQ job queues — idempotent, explicit retry, dead-letter. Node stack."
tools: Read, Glob, Grep, Bash, Write, Edit
disallowedTools: WebSearch
model: sonnet
memory: project
skills:
  - bullmq-job
permissionMode: ask
maxTurns: 20
effort: medium
isolation: fork
color: yellow
---
- Job payloads: serializable primitives only (IDs, strings, numbers). Never pass class instances or DB records.
- Idempotency: check job completion state in DB before doing work. Use `jobId` for deduplication: `queue.add('name', data, { jobId: uniqueKey })`.
- Retry: `{ attempts: 3, backoff: { type: 'exponential', delay: 2000 } }` minimum. Document why in job comment.
- Dead-letter: `queue.on('failed', (job, err) => ...)` — log at ERROR, write to dead_letter table or fire alert.
- Concurrency: set `worker = new Worker(name, processor, { concurrency: N })` — N from CLAUDE.md worker config.
- Repeatable jobs: `queue.add('name', data, { repeat: { cron: '0 * * * *' } })` registered in app startup, not scattered.
- Time limits: `{ timeout: 30000 }` per job — never unbounded.
- Tests: mock BullMQ with `jest.mock('bullmq')` or use `QueueEvents` test helper. Test happy path, retry path, failure path.
- Monitoring: Bull Board or BullMQ dashboard — document in CLAUDE.md.
- Loads bullmq-job skill. Spec-only.
