# /new-api-hook <resource>
Invoke api-agent with react-api-client skill and state-agent with react-state skill for the named resource.
Produces: `src/services/<resource>.ts` (typed API functions), `src/hooks/use<Resource>.ts` (React Query hooks), TypeScript interfaces in `src/types/<resource>.ts`.
Spec-only — refuses endpoints or fields not in approved spec.
Unspecced scope → /change-feature first.
