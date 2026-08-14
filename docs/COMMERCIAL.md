# Commercial Model — what is actually sold, and how the IP is protected

## The honest constraint
sdlc-atlas's client-side layers are markdown that Claude Code must read in
plaintext. Anything executing on a customer's machine is readable (and behaviour
leaks prompts anyway — extraction is an unwinnable game). So the product is NOT
the files. What is sold:
1. **The system that keeps improving** — quarterly platform updates, new stacks,
   promotion harvests, cross-customer learning. A copied snapshot rots in months.
2. **Customization** — the org layer, compliance packs, project layers, seeded
   knowledge.md. The template is days; making it right for THEIR org is the work.
3. **Support & accountability** — SLA, a number to call, someone to be responsible.
4. **The why** — ARCHITECTURE.md's research rationale. Teams that copy files
   without it "simplify" the gates away and recreate the documented failures.
Sharing fear is answered by the LICENSE, not by technology — enterprises don't
pirate tooling; solo devs who share it are free marketing for a non-paying tier.

## Tiers (open-core)
| Tier | Gets | Pays |
|---|---|---|
| Free / open base | Platform layer + 1 stack + minimal profile, public repo | — (adoption; becomes the standard) |
| Pro | All stacks, updates, standard profile, email support | per-team / month |
| Enterprise | Org-layer design, compliance packs (HIPAA/SOC2), onboarding of N projects, training, quarterly harvest, SLA | setup fee + annual |

Non-copyable add-on worth building: a hosted dashboard (proposal review queue,
gate pass-rates, traceability & evidence reports for auditors).

## Sales motion
Sell a **two-week paid pilot**, not the platform: one real team, one real repo,
five real work items through /feature → PR. Measure before/after: time from
story to PR-ready, and gate-caught defects. The rollout deal closes on the
customer's own numbers. Openness is the trust pitch — "every rule our agents
follow is a file you can audit" — decisive in regulated industries.

## v2 IP protection — hybrid MCP (build AFTER first paying customer)
| Component | Lives | Why |
|---|---|---|
| L0 process layer (orchestrator, spec-agent, governance, gates) | **Vendor MCP server — hidden** | The hard-won IP; stack-agnostic; executes server-side, prompts never transmitted |
| L1 stack + L3 project layers (+ knowledge.md) | **Customer machine — visible** | About THEIR code, half-written with them, worthless without the process engine |
The visible part is the part not worth stealing; the stealable part is invisible.
Trust story survives: "your code and your rules stay on your machines." Caveats:
behavioural leakage never fully disappears (outputs reveal roughly WHAT, never
HOW), and the server is real engineering (~weeks) — sequence it after demand is
proven with the file-based version + license.
