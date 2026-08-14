# /new-route <route-path>
Invoke router-agent with vue-router skill for a new route/page.
Produces: lazy-loaded route entry in `src/router/index.ts`, page component under `src/views/` (via component-agent), guard/meta wiring if the spec requires auth.
Spec-only — refuses routes or navigation behaviour not in approved spec.
Unspecced scope → /change-feature first.
