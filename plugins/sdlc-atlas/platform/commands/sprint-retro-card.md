---
name: sprint-retro-card
description: >-
  Generates a cross-repository retro report computing velocity-streaks and git metrics.
---

# /sprint-retro-card

**Gathers commit history and active streaks across your local repositories.**

## Invocation

```bash
/sprint-retro-card [--days N]
```

## Process

1. Identify the parent directory of the current repository to locate neighboring workspaces.
2. Run `git log` across all detected Git repositories for the past `N` days (default: 7).
3. Compute the **`cross-repo-metrics`**:
   - Total commits across all repos.
   - Number of files changed.
   - Top active repositories.
4. Calculate the developer's **`velocity-streak`**:
   - Parse git commit timestamps.
   - Find the number of consecutive calendar days with at least one commit or approved quality-gate execution.
5. Output the results in a structured scorecard format and save it to `.claude/memory/sprint_retro_card.json`.

## Output

```
── Sprint Retro Card ──────────────────────
Date range: Past 7 days
Repos Scanned: 4 (my-app, auth-service, platform, dev-tools)

  • Total Commits:      42
  • Files Modified:     108
  • Active Repos:       my-app (30), auth-service (12)
  • Velocity Streak:    5 consecutive days active! 🔥

Keep the shipping momentum going!
───────────────────────────────────────────
```
