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

## Committing and Publishing Submodule Changes

Changes that span multiple repositories (this repo + submodules) require extra steps to publish correctly.

### Commit order

1. **Commit inside the submodule first** (`deps/davids-dotfiles-common`, `deps/davids-dotfiles-private`).
2. **Push the submodule** to its remote so the commit is reachable:
   ```bash
   cd deps/<name> && git push origin main
   ```
3. **Update the parent repo's submodule pointer** and commit:
   ```bash
   cd /path/to/dotfiles
   git add deps/<name>
   git commit -m "update <name> submodule"
   ```
4. **Push the parent repo**.

> Skipping step 2 causes the Nix flake build to fail with:
> `Cannot find Git revision '<sha>' in ref 'refs/heads/main' of repository '...'`
> because the flake fetches the submodule directly from the remote using the pinned SHA.

### When submodule main branch moves forward

If the submodule's remote `main` advances (e.g. someone pushed new commits) while you have local commits on a detached HEAD, your commits are not on `main` and will be lost when the submodule is updated. To avoid this:

- Work on the submodule with `git checkout main` before making changes, so commits land on the branch.
- After the submodule's remote advances, rebase your local work:
  ```bash
  cd deps/<name>
  git fetch origin
  git rebase origin/main
  git push origin main
  ```
- Then update the parent repo pointer as described above.
