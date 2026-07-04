## Environment

This machine is declaratively managed by Nix. System configuration, packages and a wealth of user files in the
current user's home directory are immutable.
The nix flake that contains the machine's configuration can be found at `~/Worktrees/dotfiles`.

## Package Management

### With nix

Declarative management over the installed packages with nix is **STRONGLY PREFERRED**.
If a command is not available in your current environment, use `nix shell nixpkgs#<package>` or `nix run nixpkgs#<package>`.

## User-level files

### Your user level memory

Your memory file is located at `@agentMemoryDirectory@/@agentMemoryFile@`. This file is managed by
home-manager and thus immutable.
