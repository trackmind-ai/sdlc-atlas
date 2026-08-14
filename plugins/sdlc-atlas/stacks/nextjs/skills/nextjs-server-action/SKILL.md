---
name: nextjs-server-action
description: Procedure for implementing Next.js Server Actions for mutations and form handling.
---
# Next.js Server Action Procedure

1. Create action in `app/<feature>/actions.ts` — mark file or function with `'use server'`.
2. Validate all inputs with Zod before any DB/API call.
3. Perform the mutation (DB write, external API call).
4. Call `revalidatePath('/affected-route')` or `revalidateTag('tag')` after successful mutation.
5. Return typed response: `{ success: true, data: T }` or `{ success: false, error: string }`.
6. In the Client Component: use `useTransition` or `useFormState` to track pending state.
7. Show loading indicator during pending; display error message on failure.
8. Never expose server secrets — actions run on the server but are callable from client.
9. Write unit test for the action logic; write integration test for the form submission flow.
10. Run lint and type-check before considering done.
