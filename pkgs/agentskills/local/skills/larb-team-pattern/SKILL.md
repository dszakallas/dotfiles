---
name: larb-team-pattern
description: "Run an agent team as a Leader supervising one active agent per role — Leader, Architect, Reviewer, Builder (LARB) — with tasks in beads, review gates, provider switching on quota, and Paseo for coordination. Use when coordinating multiple agents on an epic, when an agent team needs supervising, or when the user asks to run/continue a LARB team."
---

# LARB team pattern

One Leader supervises three roles. Exactly one agent per role is **active** at a time; others exist as profiles for provider switching.

```
Leader ── assigns epics/tickets, schedules, records, reports
  ├── Architect   design documents, ticket breakdown, epic review
  ├── Reviewer    task briefs to Builder, review gate, next task in epic
  └── Builder     implementation, repair, commit on instruction
```

The Leader does not implement, review, or relay technical findings. Two agents that can message each other must message each other.

## Roles

**Leader**
- Create one agent per role per provider profile at project start. If a role has one profile, create one agent.
- Name agents `<Role> [<Provider>]` (`Reviewer [1]`, `Architect [2]`, `Builder [10]`).
- Assign epics to the Reviewer and design tasks to the Architect; schedule by dependency and user preference.
- Record new epics and tickets from the user; keep beads and the progress tracker current.
- Create a Paseo heartbeat for periodic supervision.
- Monitor agents for quota errors and switch provider pairs.
- Escalate to the user: product decisions, scope, quota, genuine blockers.
- Never edit product code, never commit on an agent's behalf, never carry technical messages between agents.

**Architect**
- Design epics: design documents, ticket breakdown, acceptance criteria.
- Short feasibility probes with ephemeral subagents, web research, GitHub search.
- Review epic implementations: if revision is needed, file follow-up bug tickets and send the work back through the Reviewer; if accepted, close the epic and report to the Leader.

**Reviewer**
- Hand the Builder one task at a time with a precise brief.
- Review against requirements, standards and testing regime.
- Send back for repair, or accept and update the bead.
- Assign the next task in the epic.
- Escalate design-soundness problems and technical blocks (quota, permissions) to the Leader.
- Ask the Architect for epic review before declaring the epic complete.

**Builder**
- Implement the task the Reviewer sent; commit only on instruction; report completion with the diff, gate result and acceptance mapping.
- Repair from Reviewer feedback, in the same session, without re-planning the ticket.

## Communication

Use Paseo for everything:

```
paseo ls                                  # who is alive, status per agent
paseo inspect <id>                        # model, mode, archive state
paseo logs <id>                           # what the agent actually did
paseo send <id> "<message>"               # task, brief, correction
paseo wait <id>                           # block until idle
paseo attach <id>                         # follow output live
paseo agent reload <id>                   # revive an existing agent (does NOT create one)
paseo archive <id>                        # retire an agent
```

**Reuse agents; never create duplicates for a role.** If a reviewer is closed or rate-limited, `paseo agent reload <id>`. Creating a second reviewer means two agents review the same diff and hand out conflicting instructions.

Route by role: Leader → Reviewer for implementation epics; Leader → Architect for design; Reviewer → Builder for tasks and findings. The Leader does not forward findings.

## Beads

Everything scheduled is a bead: epics (`9rm`), children (`9rm.7`), bugs (`7hd`), chores. Record in the bead: acceptance criteria, design links, deferrals with their reason, and a tracking bead for anything not fixed now.

```bash
bd create "title" -d "description and acceptance" -p 1 -t bug
bd show <id>                 # read before assigning
bd update <id> --append-notes "…"
bd dep add <child> <parent>  # sequencing that a dispatch must respect
bd close <id> --reason "committed as <hash>: what shipped, gate result, deferrals"
```

An acceptance item that cannot be met becomes a deferral bead and is named in the close reason. Never quietly absorb a fix for a closed bead into the current ticket — commit it separately and reference the tracking bead.

## Commit gate

A Builder commits only when the Reviewer's **same message** contains ACCEPT **and** an explicit commit instruction. Plan acceptance is not implementation acceptance. A commit without that instruction is a defect regardless of quality.

Two commits in one round are fine when a fix belongs to another bead: split by files or hunks, first commit proved standalone, then the feature.

## Verification rules

Attach these to every brief; reject against them by name:

- **A test must bite.** Break the protected line, watch the test fail, restore, watch it pass. Report both directions.
- **UI-observable behaviour needs a UI test.** No calling services or repositories inside `page.evaluate` to simulate a user action.
- **A count or existence check that can be vacuously true is not an assertion.**
- **Local state is never proof of an authoritative write.** Publish after the authority acknowledges; restore the committed state on refusal.
- **Stale async responses never overwrite newer state.** Capture identity or epoch; drop on mismatch.
- **Never re-run a failing test to reclassify it.** A non-reproducing failure is unexplained, not a flake.
- **No weakened assertions, widened timeouts, or retries to reach green.**
- **No unit-test proxies for user-visible acceptance.** Unit tests may cover pure logic; the user path needs a browser test.

A green gate means "the suite passed", not "the acceptance is met". Review the mapping, item by item, naming the test that proves it.

## Provider pairs and quota

The Reviewer and Architect share a provider and **switch together**. Never mix one Codex reviewer with one Claude architect.

- Watch for quota messages in agent replies; a rate-limited reviewer blocks the whole epic.
- Switch by reloading the existing counterpart on the other provider — do not create new agents.
- When a reset is imminent, decide explicitly: wait, or switch. Waiting is fine for minutes, not hours; say the cost to the user rather than silently idling.
- Stand the previous reviewer down (stop sending it work) but leave it idle so a later switch is instant.

## Context hygiene

Long sessions degrade. Compact the agent in place rather than replacing it:

```bash
opencode api post /api/session/<sessionId>/compact --data '{}'
```

Take `sessionId` from the agent's runtime info. Compact at idle boundaries near roughly half the window, and again if quality drops. After compaction, tell the agent to re-read the bead and the design before continuing. Replace a builder only if compaction fails or the session is incoherent — and hand the new one the uncommitted tree, the invariant list and an explicit "do not reset" warning.

## Progress tracker

Keep a dashboard ticker and an activity log current: current ticket and stage, gate numbers, bead states, blockers. The tracker is how a human can see the loop without reading agent logs.

## Heartbeat

Create a recurring Paseo heartbeat for supervision. Each tick, cheaply:

1. `paseo ls` — who is running, idle, blocked, closed.
2. `git log --oneline -3` and `git status --short` — commits since last tick, uncommitted scope, forbidden files.
3. Bead state for the active ticket.
4. Gate numbers and whether failures are classified.
5. Update tracker; intervene only for product decisions, scope, quota, or genuine blockers.

Do not use the tick to relay technical messages. If two agents disagree, they resolve it.

## Signs the pattern is failing

- The Leader is forwarding findings between agents.
- Two agents hold the same role.
- Rounds end with "accepted" but the same defect returns under a new name.
- Tests pass that cannot fail.
- An epic outlives a builder's context window.
- Commits land without an ACCEPT and instruction in one message.

Fix the topology or the brief, not the symptom.
