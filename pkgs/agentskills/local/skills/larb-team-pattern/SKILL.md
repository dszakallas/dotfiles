---
name: larb-team-pattern
description: "Run an agent team as a Leader supervising one active agent per role — Leader, Architect, Reviewer, Builder (LARB) — using Paseo agent profiles as blueprints, tasks in beads, a review gate, provider switching on quota, and Paseo tools for coordination. Use when coordinating multiple agents on an epic, when an agent team needs supervising, or when the user asks to run or continue a LARB team."
---

# LARB team pattern

One Leader supervises three roles. Exactly one agent per role per provider profile exists, and exactly one of them is **active** at a time; the others are counterparts for quota switching.

```
Leader ── assigns epics/tickets, schedules, records, reports
  ├── Architect   design documents, ticket breakdown, epic review
  ├── Reviewer    task briefs to Builder, review gate, next task in epic
  └── Builder     implementation, repair, commit on instruction
```

The Leader does not implement, review, or relay technical findings. Two agents that can message each other must message each other.

## Profiles are the blueprint

Paseo agent profiles encode provider, model, thinking level, mode and feature values. They are authored by the user and are the **only** source of those settings.

- List them with the Paseo profile tool before creating anything.
- Create each agent from a profile: copy provider, model, thinking option and mode exactly. Never invent, upgrade or hand-pick a setting.
- One agent per role per profile: `Builder`, `Reviewer [Claude]`, `Reviewer [Codex]`, `Architect [Claude]`, `Architect [Codex]`, and any other provider the user has profiles for.
- **Audit the team against the profiles at start and after every switch.** `paseo inspect <id>` shows live values; if they drift from the profile, correct them (`paseo update agent` / provider mode) instead of recreating the agent.
- If no profile fits a role, stop and ask. A wrong thinking level or permission mode changes cost and safety silently, and it looks like model behaviour rather than misconfiguration.

## Roles

**Leader**
- Create the team from profiles and immediately detach every started team member (`paseo agent detach <id>`) so each runs as a top-level workspace tab instead of remaining nested as a subagent. Revive existing agents with `paseo agent reload <id>` rather than creating duplicates.
- Assign epics to the Reviewer and design tasks to the Architect; schedule by dependency and user preference.
- Record new epics and tickets from the user; keep beads and the progress tracker current.
- Create a Paseo heartbeat for periodic supervision.
- Monitor for quota errors and switch provider pairs.
- Escalate to the user: product decisions, scope, quota, genuine blockers.
- Never edit product code, never commit on an agent's behalf, never carry technical messages between agents.

**Architect**
- Design epics: store the design and plan in the owning bead's `design` field (not as markdown files in the worktree), create the ticket breakdown, and record acceptance criteria.
- Short feasibility probes with ephemeral subagents, web research, GitHub search.
- Review epic implementations: if revision is needed, file follow-up bug tickets and send the work back through the Reviewer; if accepted, close the epic and report to the Leader.

**Reviewer**
- Hand the Builder one task at a time with a precise brief.
- Review against requirements, standards and the testing regime.
- Send back for repair, or accept and update the bead.
- Assign the next task in the epic.
- Escalate design-soundness problems and technical blocks (quota, permissions) to the Leader.
- Ask the Architect for epic review before declaring the epic complete.

**Builder**
- Implement the task the Reviewer sent; commit only on instruction; report the diff, gate result and acceptance mapping.
- Repair from Reviewer feedback in the same session.

## Communication

Coordination runs through Paseo:

```
profile list                              # the blueprints; read before creating agents
paseo ls                                  # who is alive and their status
paseo inspect <id>                        # model, thinking, mode, archive state
paseo logs <id>                           # what the agent actually did
paseo send <id> "<message>"               # task, brief, correction
paseo wait <id>                           # block until idle
paseo attach <id>                         # follow output live
paseo agent detach <id>                   # make a started team member independent (top-level tab)
paseo agent reload <id>                   # revive an existing agent (never create a duplicate)
paseo archive <id>                        # retire an agent
```

**Reuse, never duplicate.** A second reviewer for the same role means two agents review the same diff and hand out conflicting instructions. If a reviewer is closed or rate-limited, reload it, or switch to the counterpart profile.

Route by role: Leader → Reviewer for implementation epics; Leader → Architect for design; Reviewer → Builder for tasks and findings.

## Beads

Everything scheduled is a bead: epics (`9rm`), children (`9rm.7`), bugs (`7hd`), chores.

```bash
bd create "title" -d "description and acceptance" -p 1 -t bug
bd create "title" -t epic -p 1 --design-file - -d "…"   # store design from stdin at creation
bd show <id>                                           # renders DESIGN (--json may return an array; unwrap [0])
bd update <id> --design-file -                         # replace design field from stdin (or --design-file <path> / --design "…")
bd update <id> --append-notes "…"
bd comment <id> --file <path>                          # append-only evidence, investigations, verdicts (or --stdin)
bd comments <id>                                       # list comments
bd dep add <child> <parent>
bd dep relate <id1> <id2>                              # link beads sharing a design
bd close <id> --reason "committed as <hash>: what shipped, gate result, deferrals"
bd dolt push                                           # push bead/design history off-machine
```

Store designs, investigation results, concrete plans for agentic development, evidence, and review verdicts in beads—not as `.md` files in the worktree by default—so every worktree reads one shared copy. Keep only general-audience user or developer documentation in the repository (requirements, specifications, code docs, runbooks).

- **Canonical plan (`design` field):** write via `--design-file <path>` (or `-` for stdin) or `--design`. Updates replace `design` wholesale; do not duplicate the plan in comments or files.
- **Long append-only material:** write investigations, evidence, and review verdicts via `bd comment <id> --file <path>` (or `--stdin`); read with `bd comments <id>`.
- **Shared plans:** store once on the primary bead (or a dedicated `decision` bead) and link related beads with `bd dep relate <id1> <id2>`.
- **Durability & migration:** run `bd dolt push` for off-machine durability since bead designs sit outside git. Before deleting a legacy plan file, wait until no in-flight work references its path and verify `bd show <id>` matches.

Record in the bead: acceptance criteria, the design, deferrals with reasons, and a tracking bead for anything not fixed now. Never absorb a fix for a closed bead into the current ticket — commit it separately and reference the tracking bead.

## Commit gate

A Builder commits only when the Reviewer's **same message** contains ACCEPT **and** an explicit commit instruction. Plan acceptance is not implementation acceptance.

Two commits in one round are fine when a fix belongs to another bead: split by files or hunks, prove the first commit standalone, then the feature.

## Verification rules

Attach these to every brief; reject against the named rule:

- **A test must bite.** Break the protected line, watch the test fail, restore, watch it pass. Report both directions.
- **UI-observable behaviour needs a UI test.** No calling services or repositories inside `page.evaluate` to simulate a user action.
- **A count or existence check that can be vacuously true is not an assertion.**
- **Local state is never proof of an authoritative write.** Publish after the authority acknowledges; restore committed state on refusal.
- **Stale async responses never overwrite newer state.** Capture identity or epoch, drop on mismatch.
- **Never re-run a failing test to reclassify it.** A non-reproducing failure is unexplained, not a flake.
- **No weakened assertions, widened timeouts, or retries to reach green.**
- **No unit-test proxies for user-visible acceptance.** Unit tests may cover pure logic; the user path needs a browser test.

A green gate means the suite passed, not that acceptance is met. Review the mapping item by item, naming the test that proves it.

## Provider pairs and quota

Reviewer and Architect share a provider and **switch together**. Never mix a Codex reviewer with a Claude architect.

- Watch for quota messages; a rate-limited reviewer blocks the whole epic.
- Switch by reloading the existing counterpart on the other provider — do not create new agents.
- Decide explicitly whether to wait or switch. Waiting is fine for minutes, not hours: state the cost to the user rather than idling silently.
- Stand the previous reviewer down but leave it idle, so the next switch is instant.

## Context hygiene

Long sessions degrade. Compact in place rather than replacing:

```bash
opencode api post /api/session/<sessionId>/compact --data '{}'
```

Take `sessionId` from the agent's runtime info. Compact at idle boundaries near half the window, and after compaction tell the agent to re-read the bead and design. Replace a builder only if compaction fails or the session is incoherent — and hand the new one the uncommitted tree, the invariants and an explicit "do not reset" warning.

## Progress tracker

Keep a dashboard ticker and activity log current: active ticket and stage, gate numbers, bead states, blockers. The tracker is how a human follows the loop without reading agent logs.

## Heartbeat

Create a recurring Paseo heartbeat for supervision. Each tick, cheaply:

1. `paseo ls` — running, idle, blocked, closed.
2. `git log --oneline -3`, `git status --short` — new commits, uncommitted scope, forbidden files.
3. Bead state for the active ticket.
4. Gate numbers and whether failures are classified.
5. Update the tracker; intervene only for product decisions, scope, quota or genuine blockers.

Do not use the tick to relay technical messages; if two agents disagree, they resolve it.

## Signs the pattern is failing

- The Leader forwards findings between agents.
- Started team members remain attached as subagents instead of detached.
- Agentic plans, designs, or investigation notes are written as markdown files in the worktree instead of stored in beads.
- Two agents share a role or provider pair.
- Live settings drift from the profiles.
- Rounds end "accepted" and the same defect returns under a new name.
- Tests pass that cannot fail.
- An epic outlives a builder's context window.
- Commits land without ACCEPT and instruction in one message.

Fix the topology or the brief, not the symptom.
