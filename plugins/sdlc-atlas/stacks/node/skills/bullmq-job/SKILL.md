---
name: bullmq-job
description: "BullMQ job implementation checklist."
---
1. `new Queue('queue-name', { connection })` — connection from shared Redis client, not inline config.
2. `new Worker('queue-name', processor, { connection, concurrency: N })` — N from CLAUDE.md.
3. Job payload: plain JSON only. `{ entityId: string, action: string }` — never class instances or Prisma records.
4. `jobId` for deduplication: `queue.add('name', data, { jobId: `${type}:${entityId}` })` — prevents duplicate jobs.
5. Retry: `{ attempts: 3, backoff: { type: 'exponential', delay: 2000 } }` minimum. Add `removeOnFail: { count: 1000 }`.
6. Idempotency check first in processor: `if (await isAlreadyProcessed(job.data.entityId)) return { skipped: true }`.
7. Dead-letter: `worker.on('failed', async (job, err) => { await writeToDeadLetterTable(job, err); alert() })`.
8. Time limit: `{ timeout: 30000 }` on every job. Handle cleanup in `removeOnFail`.
9. Repeatable jobs: register centrally in `src/jobs/schedule.ts`, loaded in app startup once.
10. `QueueEvents` for event tracking: `queueEvents.on('completed', ...)` for monitoring.
11. Graceful shutdown: `await worker.close()` on SIGTERM/SIGINT before process exit.
12. Bull Board: mount `createBullBoard` at `/admin/queues` behind auth middleware.
13. Logging: `job.log('Processing...')` inside processor for per-job audit trail.
14. Tests: `jest.mock('bullmq')`. Assert `queue.add` called with correct payload and options.
15. Never access `req`/`res` inside a job processor — jobs run outside request context.
