# User-level memory

## Environment

This machine is declaratively managed by Nix. System configuration, packages and a wealth of user files in the
current user's home directory are immutable.
The nix flake that contains the machine's configuration can be found at `~/Worktrees/dotfiles`.

## Package Management

### With nix

Declarative management over the installed packages with nix is **STRONGLY PREFERRED**.
If a command is not available in your current environment, use `nix shell nixpkgs#<package>` or `nix run nixpkgs#<package>`.

@packageManagentExtraH3@

## User-level files

### Your user level memory

Your memory file is located at `@agentMemoryDirectory@/@agentMemoryFile@`. This file is managed by
home-manager and thus immutable. When asked to record something in user-level memory, you should add them
to the unmanaged memory file at `@agentMemoryDirectory@/unmanaged.MEMORY.MD`, which is included in the main
memory file.

@userLevelFilesExtraH3@

## Worktrees

Worktrees are project directories located in `~/Worktrees`. Each worktree has a git repository associated with it,
e.g it was created with `git clone` or `git worktree add`. You should treat each worktree as a separate project and
follow best practices when working with git repositories.

### Basics

Basic code of conduct when working in git worktrees:

- **No `git add .`:** NEVER run blanket commands such as `git add .`. Surgically add only the files you have
  intended to change.
- **Surgical Changes:** Ensure that each commit contains only relevant changes. Review `git status` carefully
  before staging.

### Devenvs

Most of the worktrees in `~/Worktrees` are configured with `devenv.nix` files, which provide a
consistent development environment, both for humans and for agents.

If the project contains a `devenv.nix` file, you should treat it as a devenv project and apply the
practices in this section.

To detect if you are already running within a `devenv` shell, check if the `DEVENV_CMDLINE`
environment variable is non-empty. If it is, you are already in the environment and can run
commands directly without the `devenv shell` prefix.

You should always execute commands from within the `devenv` shell,
which provides access to all necessary tools and dependencies.

To enter the `devenv` shell interactively, run:

```bash
devenv shell --no-tui --quiet
```

You can, then run any command within the shell, for example:

```bash
npm version
npm run build
```

To run a one-off command within the `devenv` shell without entering it interactively, prefix the
command with `devenv shell --no-tui --quiet --`, for example:

```bash
devenv shell --no-tui --quiet -- npm run build
```

@workTreesExtraH3@

@./unmanaged.MEMORY.MD
