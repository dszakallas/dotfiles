---
name: git-operator
description: >-
  Manage Git repositories and isolated agent worktrees with git operator. Use this skill whenever creating,
  cloning, listing, removing, or cleaning up repositories managed through the ~/Repos bare-repository and
  ~/Worktrees worktree convention, especially before making changes in a new agent worktree.
tags: [git, worktree, repositories, agents]
---

# Git Operator

`git operator` keeps each repository's shared Git data in a bare repository and
uses linked worktrees for checkouts. This lets agents work in isolation without
sharing an index or branch checkout.

Use `git operator help` for the command synopsis. `git operator --help` asks
Git for a manual page and may not reach the command.

## Create repositories

Create a new local repository and its initial `main` worktree:

```bash
git operator init <project>
```

Clone an existing remote and check out its default branch:

```bash
git operator clone <remote-url> <project>
```

Both commands support these mutually exclusive options:

```bash
--no-worktree
--worktree-name <name>
```

Use `--no-worktree` only when a bare repository is needed without a checkout.

## Agent worktrees

Create a fresh, up-to-date worktree before changing a managed repository:

```bash
git operator worktree add --fetch <project> <worktree-name> origin/main
```

`--fetch` refreshes remote-tracking refs before resolving `origin/main`; omit
it only when the existing local refs are intentionally sufficient. A supplied
start point creates a new branch. If that branch already exists, omit the
start point to attach it instead.

Inspect and remove worktrees with:

```bash
git operator worktree list <project>
git operator worktree remove <project> <worktree-name>
```

Remove a worktree only after confirming it is clean. Do not use `--force`
unless the user explicitly accepts losing its uncommitted work.

## Repository deletion

`git operator delete <project>` refuses to delete repositories with active
worktrees. `git operator delete --force <project>` removes every registered
worktree and then the bare repository, so require explicit user authorization.
