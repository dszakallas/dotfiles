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

Your memory file is located at `@agentUserDirectory@/@agentMainMemoryFile@`. This file is managed by
home-manager and thus immutable. When asked to record something in user-level memory, you should add them
to the unmanaged memory file at `@agentUserDirectory@/unmanaged.MEMORY.MD`, which is included in the main
memory file.

@userLevelFilesExtraH3@

## Worktrees

Basic code of conduct when working in git repository worktrees:

- **No `git add .`:** NEVER run blanket commands such as `git add .`. Surgically add only the files you have
  intended to change.
- **Surgical Changes:** Ensure that each commit contains only relevant changes. Review `git status` carefully
  before staging.

@workTreesExtraH3@

@./unmanaged.MEMORY.MD
