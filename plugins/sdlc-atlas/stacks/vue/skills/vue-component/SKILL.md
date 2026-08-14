---
name: vue-component
description: Procedure for building Vue 3 Single-File Components with the Composition API and TypeScript.
---
# Vue Component Procedure

1. Use `<script setup lang="ts">` only — no Options API, no mixins, no `this`.
2. Props: `interface Props { ... }` + `withDefaults(defineProps<Props>(), {...})`. No `any`, no bare `defineProps(['x'])`.
3. Emits: `defineEmits<{ submit: []; 'update:modelValue': [value: string] }>()`; kebab-case in templates, camelCase in script.
4. v-model: use `defineModel<T>()` (Vue 3.4+) instead of manual `modelValue` + `update:modelValue` plumbing.
5. File naming: PascalCase (`UserCard.vue`); base/presentational components prefixed `Base`/`App`; tightly-coupled children prefixed with parent name (`UserProfileAvatar.vue`).
6. Folder layout: `src/components/<Name>.vue` + `<Name>.test.ts`; route pages under `src/pages/` or `src/views/`.
7. Template: `v-for` always paired with `:key` (stable ID, never index); never `v-if` on the same element as `v-for` — filter via `computed` first.
8. Async state: render a loading state and an error state; never leave the UI blank during fetch.
9. SFC block order: `<script setup>` → `<template>` → `<style scoped>`.
10. Tests: `@vue/test-utils` `mount()`; assert rendered text/emitted events, not internals. One test file per component.
11. Run `npx vue-tsc --noEmit` and `npx eslint .` before considering done.
