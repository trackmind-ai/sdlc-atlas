# Governance

sdlc-atlas is maintained by **Trackmind** (`oss@trackmind.com`). It currently uses a
**Benevolent Dictator For Now (BDFN)** model, with the goal of moving toward a broader
steering committee as the project matures and outside contributors establish a track record.

For the platform's internal capability governance (how agents/skills are added mid-pipeline), see [docs/GOVERNANCE.md](docs/GOVERNANCE.md).

---

## Roles

### Maintainers
Write access to the repo. They review and merge PRs, triage issues, and cut releases.

### Contributors
Anyone who has had a PR merged. Listed in release notes.

### Users
Anyone using the platform. Can open issues, participate in Discussions, and vote on feature requests.

---

## Decision making

| Change type | Process |
|-------------|---------|
| Bug fixes, doc updates, new skills | Any maintainer merges after 1 approval |
| New agents, changed gate behavior | 2 maintainer approvals required |
| Breaking changes, new pipeline phases | 7-day issue/Discussion open period + 2 approvals |
| Governance, CODEOWNERS, licensing | All active maintainers must approve |

---

## Adding a maintainer

1. Open an issue titled `[Maintainer nomination] @username`
2. Existing maintainers vote over 7 days (simple majority)
3. If accepted, the account is added to the `@trackmind-ai/maintainers` GitHub team, which is
   what `CODEOWNERS` resolves against

---

## Changing this document

Propose via PR. All active maintainers must approve.
