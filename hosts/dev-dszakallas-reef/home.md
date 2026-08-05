## Environment

This machine is an Ubuntu Linux virtual machine. Only the current user's home directory is declaratively
managed by Nix, via home-manager; a wealth of user files there are immutable.
System-level packages and configuration are not managed by us and remain mutable.
The nix flake that contains the home-manager configuration can be found at `~/Worktrees/dotfiles`.

## Package Management

### With nix

Declarative management over the installed user-level packages with nix is **STRONGLY PREFERRED**.
If a command is not available in your current environment, use `nix shell nixpkgs#<package>` or `nix run nixpkgs#<package>`.
System-level packages may be installed imperatively with `apt`, but prefer nix when possible.

## User-level files

### Your user level memory

Your memory file is located at `@agentMemoryDirectory@/@agentMemoryFile@`. This file is managed by
home-manager and thus immutable.
