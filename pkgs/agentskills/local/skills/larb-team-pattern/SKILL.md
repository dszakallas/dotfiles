---
name: larb-team-pattern
description: "Run an agent team as a Leader supervising one active agent per role — Leader, Architect, Reviewer, Builder (LARB) — using Paseo agent profiles as blueprints, tasks in beads, a scope-locked review gate, lazy on-demand provider switching on quota, structured supervision heartbeats, and Paseo tools for coordination. Use when coordinating multiple agents on an epic, when an agent team needs supervising, or when the user asks to run or continue a LARB team."
---

# LARB team pattern

One Leader supervises three roles. Exactly one agent per role is **active** at a time. Counterpart agents on alternate providers are created **lazily**—only on quota errors or explicit user request—never upfront.

```
Leader ── assigns epics/tickets, schedules, supervises, reports
  ├── Architect   (persistent) design documents, ticket breakdown, scope/divergence judgment, epic closeout
  ├── Reviewer    (ephemeral per epic) task briefs to Builder, scope-locked review gate, next task in epic
  └── Builder     (ephemeral per epic) implementation, repair, commit on instruction
```

The Leader does not implement, review, or relay technical findings. Two agents that can message each other must message each other.

## Profiles and lifecycles

Paseo agent profiles encode provider, model, thinking level, mode, and feature values. They are authored by the user and are the **only** source of those settings. Supported providers include `antigravity`, `opencode`, `claude`, and `codex`.

- List profiles with the Paseo profile tool before creating anything.  
- Create each agent from a profile: copy provider, model, thinking option, and mode exactly. Never invent, upgrade, or hand-pick a setting.  
- **Audit the team against the profiles at start and after every switch.** `paseo inspect <id>` shows live values; if they drift from the profile, correct them (`paseo update agent` / provider mode) instead of recreating the agent.  
- If no profile fits a role, stop and ask. A wrong thinking level or permission mode changes cost and safety silently, and it looks like model behaviour rather than misconfiguration.

| Role | Lifecycle | Creation Policy | Context Full Action | Quota Action |
| :---- | :---- | :---- | :---- | :---- |
| **Leader** | Persistent | Upfront | Compact in place (\~55–60%) | Escalate to user |
| **Architect** | Persistent | Upfront (primary profile) | Compact in place (\~80–90%) | Lazily create counterpart *only* if Architect is rate-limited |
| **Reviewer** | Ephemeral (per epic) | Created at epic start | Compact in place (\~75–80% at idle) | Lazily create counterpart on alternate profile; stand down old one |
| **Builder** | Ephemeral (per epic) | Created at epic start | Compact in place (\~60–75% at idle) | Lazily create counterpart on alternate profile; stand down old one |

## Roles

**Leader**

- Create persistent agents (Architect) upfront and ephemeral agents (Reviewer, Builder) at epic start from profiles. Immediately detach every started team member (`paseo agent detach <id>`) so each runs as a top-level workspace tab instead of remaining nested as a subagent. Revive existing agents with `paseo agent reload <id>` rather than creating duplicates.  
- Assign epics to the Reviewer and design/feature-scoping tasks to the Architect; schedule by dependency and user preference.  
- File bug tickets (`-t bug`) only; never create feature tickets (route feature requests to the Architect). Keep beads and the progress tracker current.  
- Run the structured supervision heartbeat: monitor liveness, context usage, git hygiene, active elapsed time vs. estimate, and repair-round counts.  
- Enforce the dual-budget trigger (active time \>= 100% of `-e` OR repair rounds \>= 3\) using the Interrupt Protocol (`paseo stop <id>`), then escalate to the Architect.  
- Monitor for quota errors and switch only the rate-limited agent lazily.  
- Archive ephemeral Reviewer and Builder agents only after the Architect completes the Epic Teardown Gate.  
- Deliver tabular status reports to the user.  
- Escalate to the user: product decisions, scope changes, unrecoverable quota blocks, genuine blockers.  
- Never edit product code, never commit on an agent's behalf, never carry technical messages between agents.

**Architect**

- Design epics: store the design and plan in the owning bead's `design` field (not as markdown files in the worktree), create the ticket breakdown, and record acceptance criteria.  
- Checkpoint decisions, open questions, and milestone progress to beads immediately so a lazily-spawned counterpart can cold-start cleanly if quota hits.  
- Create all feature tickets (`-t feature`) and supply time estimates (`-e <minutes>`) for every feature ticket; only the Architect adds feature tickets.  
- Run short feasibility probes with ephemeral subagents, web research, and GitHub search.  
- Review dual-budget escalations: decide whether the in-flight implementation matches the specification or has diverged from the design; edit estimates, change/add/remove tickets, or ask the user for input before the loop resumes.  
- Execute Epic Closeout: verify all child beads are closed, acceptance criteria are met, `git status --short` is clean, and `bd dolt push` succeeds. If revision is needed, file follow-up bug tickets and send the work back through the Reviewer; if accepted, close the epic bead (`bd close <epic_id>`) and notify the Leader.

**Reviewer**

- Hand the Builder one task at a time with a precise brief.  
- **Scope-Lock:** Reject implementation *only* for (a) unmet acceptance criteria in the bead, (b) a named Verification Rule violation, or (c) a genuine bug/regression. Out-of-scope improvements or architectural nice-to-haves must be logged via `bd comment` as deferrals—never used to block the current ticket.  
- Send back for repair (capped at 3 rounds per ticket), or accept and update the bead.  
- Assign the next task in the epic.  
- Escalate design-soundness problems, 3rd-round repair failures, and technical blocks (quota, permissions) to the Leader.  
- Request Architect epic review before declaring the epic complete.

**Builder**

- Implement the task the Reviewer sent; commit only on instruction; report the diff, gate result, and acceptance mapping.  
- Repair from Reviewer feedback in the same session.

## Communication

Coordination runs through Paseo:

```
profile list                              # the blueprints; read before creating agents
paseo ls                                  # who is alive and their status
paseo inspect <id>                        # model, thinking, mode, archive state, context usage
paseo logs <id>                           # what the agent actually did
paseo send <id> "<message>"               # task, brief, correction
paseo wait <id>                           # block until idle
paseo stop <id>                           # deterministically halt an active turn
paseo attach <id>                         # follow output live
paseo agent detach <id>                   # make a started team member independent (top-level tab)
paseo agent reload <id>                   # revive an existing agent (never create a duplicate)
paseo archive <id>                        # retire an ephemeral agent after epic closeout
```

**Reuse, never duplicate.** A second active agent for the same role means conflicting instructions. If an agent is closed, reload it; if rate-limited, switch lazily to an alternate provider profile.

Route by role: Leader \-\> Reviewer for implementation epics; Leader \-\> Architect for design and escalations; Reviewer \-\> Builder for tasks and findings.

## Beads

Everything scheduled is a bead: epics (`9rm`), children (`9rm.7`), bugs (`7hd`), chores.

```sh
bd create "title" -d "description and acceptance" -p 1 -t bug
bd create "title" -t feature -e 60 -p 1 -d "…"          # Architect only; feature tickets require -e <minutes>
bd create "title" -t epic -p 1 --design-file - -d "…"   # store design from stdin at creation
bd show <id>                                           # renders DESIGN (--json may return an array; unwrap [0])
bd update <id> -e <minutes>                            # Architect updates time estimate
bd update <id> --design-file -                         # replace design field from stdin (or --design-file <path> / --design "…")
bd update <id> --append-notes "…"
bd comment <id> --file <path>                          # append-only evidence, investigations, verdicts, deferrals (or --stdin)
bd comments <id>                                       # list comments
bd dep add <child> <parent>
bd dep relate <id1> <id2>                              # link beads sharing a design
bd close <id> --reason "committed as <hash>: what shipped, gate result, deferrals"
bd dolt push                                           # push bead/design history off-machine
```

Ticket creation and estimates: only the Architect creates feature tickets (`-t feature`), and every feature ticket must include a time estimate (`-e <minutes>`). The Leader may only create bug tickets (`-t bug`).

Store designs, investigation results, concrete plans for agentic development, evidence, and review verdicts in beads—not as `.md` files in the worktree by default—so every worktree reads one shared copy. Keep only general-audience user or developer documentation in the repository (requirements, specifications, code docs, runbooks).

- **Canonical plan (`design` field):** write via `--design-file <path>` (or `-` for stdin) or `--design`. Updates replace `design` wholesale; do not duplicate the plan in comments or files.  
- **Long append-only material:** write investigations, evidence, review verdicts, and out-of-scope deferrals via `bd comment <id> --file <path>` (or `--stdin`); read with `bd comments <id>`.  
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

## Lazy provider switching & cross-provider handoff

Switch **only** the agent that hits a quota limit (or on explicit user request). Do not switch idle roles (e.g., do not replace the Architect when only the Reviewer hits quota).

- If a counterpart on an alternate provider already exists, revive it with `paseo agent reload <id>`. Otherwise, lazily create it from the alternate profile, detach it, and audit it with `paseo inspect <id>`.  
- Stand the rate-limited agent down but leave it idle so switching back is instant.  
- Decide explicitly whether to wait or switch. Waiting is fine for minutes, not hours: state the cost to the user rather than idling silently.

**Cross-Provider Handoff Bundle:** Never feed full raw `paseo logs <id>` to a replacement agent—it wastes context on noisy tool traces. Hand over only:

1. **Beads (Canonical State):** Direct the replacement to read `bd show <id>` and `bd comments <id>`.  
2. **Repo Snapshot:** Provide `git status --short`, `git diff --stat`, and `git log --oneline -3`.  
3. **Interrupted Turn Tail:** Provide only the last 1–2 turns (\~50–100 lines) of `paseo logs <id>` showing what was interrupted mid-flight, with instructions to verify it against the repo and bead before acting.

## Interrupt protocol (dual-budget & stalls)

When escalating an active ticket (active elapsed time \>= 100% of `-e`, repair rounds \>= 3, or a deadlock):

1. **Deterministic Halt:** Run `paseo stop <builder_id>` and `paseo stop <reviewer_id>`.  
2. **Worktree Sanity Check:** Run `git status --short` and verify no stale `.git/index.lock` or orphaned test/build processes remain.  
3. **Escalate:** Send the bead ID, active elapsed time, repair-round count, and `git diff --stat` to the Architect for scope/divergence judgment.  
4. **Resume Primer:** When resuming after Architect resolution, instruct the stopped agents: *"You were stopped mid-turn for an Architect review. Check `git status` and re-read bead `<id>` before continuing—do not assume your last interrupted tool call completed."*

## Context hygiene

Long sessions degrade. Compact in place rather than replacing an agent:

```sh
opencode api post /api/session/<sessionId>/compact --data '{}'
```

Take `sessionId` from the agent's runtime info. Compact at idle boundaries around 55–60% window utilization (or stop, compact, and resume if busy at \>= 75%). After compaction, instruct the agent to re-read the bead and its design field. Replace an agent only if compaction fails or the session is incoherent—and hand the replacement the uncommitted tree, the invariants, and an explicit "do not reset" warning.

## Epic teardown gate

Ephemeral Reviewer and Builder agents are archived per epic only after a two-stage closeout:

1. **Architect Closeout:** Reviewer requests epic review \-\> Architect verifies all child beads are closed, acceptance criteria are met, `git status --short` is clean, and `bd dolt push` succeeds \-\> Architect closes the epic (`bd close <epic_id>`) and notifies the Leader.  
2. **Leader Archive:** After confirming the epic bead is closed and the working tree is clean, the Leader runs `paseo archive <reviewer_id>` and `paseo archive <builder_id>`, then updates the status report.

## Supervision heartbeat

Create a recurring Paseo heartbeat for supervision.

- **Cadence:** Every **5–10 minutes** during active builds (or immediately on agent escalation). Back off to **20–30 minutes** (or pause) while waiting on user input or Architect design.  
- **Anti-Spam State Rule:** Track an escalation state per ticket (`running`, `paused_for_architect`, `waiting_on_user`). While paused or waiting, do not re-send escalations and do not count paused/quota time toward the ticket's active elapsed estimate.

### Per-tick inspection checklist

| Check | Command / Source | What to Measure |
| :---- | :---- | :---- |
| **1\. Liveness & Errors** | `paseo ls`, tail of `paseo logs <id>` | Crashed/closed agents, quota/429 errors, tool-permission blocks. |
| **2\. Context Window** | `paseo inspect <id>` / runtime info | Context utilization % for Builder, Reviewer, and Architect. |
| **3\. Progress & Git** | `git log --oneline -3`, `git status --short` | New commits (verify ACCEPT \+ commit instruction), stray `.md` plans, dirty tree. |
| **4\. Dual Budget** | `bd show <id>`, `bd comments <id>` | Active elapsed minutes vs. `-e <minutes>`; count of Reviewer rejection rounds. |
| **5\. Stall Detection** | Timestamp of last meaningful log/commit | No commit, review verdict, or tool progress for \>= 2 consecutive ticks. |

### Decision & escalation matrix

| Condition | Action |
| :---- | :---- |
| **Context \>= 55% AND agent is idle** | Compact in place; send `"Re-read bead <id> and its design field before continuing."` |
| **Context \>= 75% AND agent is busy** | Run `paseo stop <id>`, compact in place, and send the Resume Primer. |
| **Active time \>= 100% of `-e` OR Repair rounds \>= 3** | Execute **Interrupt Protocol**; set ticket state to `paused_for_architect`; escalate to Architect. |
| **Quota / 429 error detected** | Lazily spawn/reload counterpart for *only* the rate-limited role; audit with `paseo inspect`; send Cross-Provider Handoff Bundle; stand down old agent. |
| **Stalled \>= 2 ticks (no quota error)** | Inspect `paseo logs <id>`. If deadlocked in Builder–Reviewer disagreement, execute Interrupt Protocol and route to Architect. If blocked on permissions/product choice, set `waiting_on_user` and escalate. |
| **Unapproved commit or `.md` plan in worktree** | Flag immediately to Reviewer/Architect as a process violation; do not fix it yourself. |
| **All checks green** | Update internal tracker / status report log only. **Do not message the agents.** |

## Leader status reports

Deliver status reports to the user in tabular format covering **all in-progress tickets** and **all tickets closed since the last report**.

- **Columns:** `Ticket Bead ID`, `Ticket Name`, `Status`, `Comments`.  
- **In-progress `Comments`:** Maintain a reverse-chronological progress brief (**newest entry on top**). On each report, observe what the loop is doing and **prepend** the new observation to the previous report's comments for that ticket.  
- **Closed `Comments`:** Record the closing commit hash, gate result, and any deferrals.

Example format:

| Ticket Bead ID | Ticket Name | Status | Comments |
| :---- | :---- | :---- | :---- |
| `9rm.7` | Add retry backoff to sync worker | In Progress (Round 2, 42/60m) | \- **14:20:** Builder fixing test assertion flagged in Round 1; gate running. \- **14:10:** Reviewer rejected Round 1 (missing failure-direction test proof). \- **13:50:** Builder implementing backoff loop and unit tests. |
| `9rm.6` | Persist cursor state in SQLite | Closed | Committed as `a1b2c3d`. All 14 unit \+ 2 UI tests green. No deferrals. |

## Signs the pattern is failing

- The Leader forwards technical findings between agents.  
- Started team members remain attached as subagents instead of detached.  
- Counterpart agents are created upfront instead of lazily on demand.  
- Agentic plans, designs, or investigation notes are written as markdown files in the worktree instead of stored in beads.  
- The Leader creates feature tickets instead of only bug tickets, or a feature ticket lacks an Architect-supplied time estimate.  
- Reviewer blocks a ticket on out-of-scope improvements instead of logging deferrals.  
- Active implementation time reaches 100% of the estimate or hits 3 repair rounds without halting via `paseo stop` for Architect review.  
- Two active agents share a role.  
- Live settings drift from the profiles.  
- Rounds end "accepted" and the same defect returns under a new name.  
- Tests pass that cannot fail.  
- Commits land without ACCEPT and instruction in one message.  
- Ephemeral agents are archived before the Architect closes the epic and verifies a clean tree.

Fix the topology or the brief, not the symptom.