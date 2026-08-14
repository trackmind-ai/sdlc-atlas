---
name: react-api-client
description: Procedure for building a typed Axios API client layer in React.
---
# React API Client Procedure

1. Create `src/lib/apiClient.ts`: single axios instance with `baseURL` from `import.meta.env.VITE_API_URL`.
2. Add request interceptor: attach `Authorization: Bearer <token>` from auth store.
3. Add response interceptor: normalize errors to a typed `ApiError` shape; trigger token refresh on 401.
4. API service modules: `src/services/<resource>.ts` — one file per resource, each function typed end-to-end.
5. Function signature: `async function getUser(id: string): Promise<UserResponse>` — explicit return types always.
6. Never call `axios.get(...)` directly in a component — always go through the service module.
7. TypeScript interfaces: `<Resource>Response`, `<Resource>CreatePayload`, `<Resource>UpdatePayload` in `src/types/<resource>.ts`.
8. Environment: `VITE_API_URL` in `.env.local` (never committed); `.env.example` committed with placeholder.
9. Tests: mock axios with `axios-mock-adapter`; assert request URL, method, payload, and parsed response type.
10. Error surfaces: service functions throw `ApiError`; callers handle via React Query's `onError` or try/catch.
