---
name: git-project
description: >-
  Manage Git repositories, isolated agent worktrees, and shared Beads workspaces with git project. Use this skill whenever creating,
  cloning, listing, removing, or cleaning up repositories managed with git project.
tags: [git, worktree, repositories, agents, beads]
---

# Git Project

`git project` keeps each repository's shared Git data in a bare repository under
the configured `reposRoot`, uses linked worktrees under `worktreesRoot` for
checkouts, and initializes a shared Beads workspace at
`<reposRoot>/<project>.git/.beads` so all worktrees share issue state via Git's
common directory without sharing an index or branch checkout.

Use `git project help` for the command synopsis, or `git project --help` for the manual page.

## Create repositories

Create a new local repository, its initial `main` worktree, and its shared Beads workspace (or reinitialize an existing project to create its `.beads` database if missing):

```bash
git project init <project>
git project init --all
```

Clone an existing remote, check out its default branch, and initialize its shared Beads workspace:

```bash
git project clone <remote-url> <project>
```

Both commands support these options (`--no-worktree` and `--worktree-name` are mutually exclusive):

```bash
--no-worktree
--worktree-name <name>
--no-beads
```

Use `--no-worktree` only when a bare repository is needed without a checkout.
Use `--no-beads` when Beads initialization should be skipped.

## Beads integration

`init` and `clone` initialize a shared Beads workspace inside the bare repository
at `<reposRoot>/<project>.git/.beads` with `<project>` as the issue prefix.
Because linked worktrees share the bare repository as their Git common directory
(`git rev-parse --git-common-dir`), standard `bd` commands (`bd ready`,
`bd list`, `bd create`, `bd show`, etc.) automatically discover the shared
`.beads` directory from any worktree of the project without extra flags or
environment variables.

## Agent worktrees

Create a fresh, up-to-date worktree before changing a managed repository:

```bash
git project worktree add --fetch <project> <wt-name> origin/main
```

`--fetch` refreshes remote-tracking refs before resolving `origin/main`; omit
it only when the existing local refs are intentionally sufficient. A supplied
start point creates a new branch. If that branch already exists, omit the
start point to attach it instead.

Inspect and remove worktrees with:

```bash
git project worktree list <project>
git project worktree remove <project> <wt-name>
```

Remove a worktree only after confirming it is clean. Do not use `--force`
unless the user explicitly accepts losing its uncommitted work.

## Migrating existing checkouts

`git project migrate <path>` converts a plain clone into a bare repository
under `<reposRoot>` and reattaches its checkouts as linked worktrees. It moves
the git directory instead of re-cloning, so uncommitted changes, untracked and
ignored files, stashes, local-only branches, and reflogs all survive.

```bash
git project migrate <worktree-path>
git project migrate --all
```

The project name comes from the basename of the `origin` fetch URL, which
need not match the directory name: a checkout at `<worktreesRoot>/<dir>` whose
origin ends in `<project>.git` becomes `<reposRoot>/<project>.git` while the
worktree keeps the name `<dir>`. Pass `--project-name <name>` when there is no
`origin` remote, or when two repositories would claim the same name.

Migration works on whole repositories. Name the primary worktree, not one of
its linked worktrees; every worktree of the repository must be a direct child
of `<worktreesRoot>`, and migrate refuses the repository outright when one is
not, naming the offenders.

`--all` walks `<worktreesRoot>`, reports every repository it cannot take, and
is a dry run unless `--yes` is given. Read the plan before applying it. Add
`--keep-backup` to keep a copy of the original git directory under
`<reposRoot>/.migrate-backup`, and `--fsck` to verify object connectivity after
each conversion.

A failed verification rolls that repository back to its original layout; other
repositories in the same run are unaffected.

Migrated worktrees do not run the `post-checkout` template hook, so per-project
worktree template files are not copied into them.

## Repository deletion

`git project delete <project>` refuses to delete repositories with active
worktrees. `git project delete --force <project>` removes every registered
worktree and then the bare repository, so require explicit user authorization.
