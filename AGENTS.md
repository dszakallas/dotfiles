# Local Dependency Development Workflow

This project uses Git submodules for local development of flake dependencies.

## Workflow

1. **Add Submodule**: Add the dependency as a submodule in the `deps/` directory if it's not already there.

   ```bash
   git submodule add <url> deps/<name>
   ```

2. **Relative Paths**: The `flake.nix` is configured to use relative paths for these dependencies:

   ```nix
   davids-dotfiles-common.url = "path:./deps/davids-dotfiles-common";
   ```

3. **Develop**: Make changes in the `deps/` directory.

4. **Test**: Run `nix` commands as usual.

## Important Notes

- **Git Tracking**: Nix requires that changes in the submodule are at least staged (if using `path:`) or committed.
- **Nix Submodule Bug**: Due to a [known issue in Nix](https://github.com/NixOS/nix/issues/13324),
  changes in submodules might not be picked up if the parent repository is clean.
  - **Instruction**: Always ensure the parent repository is "dirty" (has unstaged/staged changes) when testing local
    submodule modifications. You can do this by adding a temporary comment or newline to a file in the root directory
    (e.g., `flake.nix` or `AGENTS.md`).
