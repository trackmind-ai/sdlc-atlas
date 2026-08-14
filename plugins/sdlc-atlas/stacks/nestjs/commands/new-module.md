# /new-module <resource>
Invoke module-agent with new-module skill for the specced domain only.
Produces: `<resource>.module.ts` with imports/controllers/providers/exports wired, feature module registered in AppModule.
Spec-only — refuses domain boundaries not in approved spec.
Unspecced scope → /change-feature first.
