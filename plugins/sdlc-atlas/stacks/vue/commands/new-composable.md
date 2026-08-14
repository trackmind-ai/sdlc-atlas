# /new-composable <useName>
Invoke composable-agent with vue-composable skill for the named composable only.
Produces: `src/composables/<useName>.ts` with `MaybeRef` inputs, reactive return values, lifecycle cleanup, and a test file.
Spec-only — refuses reactive logic not tied to an approved spec requirement.
Unspecced scope → /change-feature first.
