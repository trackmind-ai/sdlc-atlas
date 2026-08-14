# /new-store <domain>
Invoke pinia-store-agent with pinia-store-pattern skill for the named domain.
Produces: `src/stores/<domain>.ts` setup store (state, computed getters, actions with loading/error handling), test file with `@pinia/testing`.
Spec-only — refuses state fields or actions not in approved spec.
Unspecced scope → /change-feature first.
