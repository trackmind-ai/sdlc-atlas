# /new-component <ComponentName>
Invoke component-agent with vue-component skill for the named component only.
Produces: `src/components/<Name>.vue` (`<script setup lang="ts">`, typed props/emits), `<Name>.test.ts`.
Spec-only — refuses fields or behaviours not in approved spec.
Unspecced scope → /change-feature first.
