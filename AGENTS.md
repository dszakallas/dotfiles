# AGENTS.md

Guidance for coding agents working in this repository.

## What this is

A personal Nix flake that configures macOS hosts via [nix-darwin](https://github.com/LnL7/nix-darwin)
and [home-manager](https://github.com/nix-community/home-manager). It builds `darwinConfigurations`
for each machine and composes reusable modules, overlays, packages, and per-user home configs.

Reusable, generic config lives in three Git submodules under `deps/`:

- `deps/davids-dotfiles-common` — public, shareable modules and lib functions
  ([dotfiles-common](https://github.com/dszakallas/dotfiles-common)).
- `deps/bikeshed-homelab` — personal machines and accounts: git and SSH user presets, the
  `bikeshed.jupiter` and `bikeshed.kolobok` modules
  ([bikeshed-homelab](https://github.com/dszakallas/bikeshed-homelab)).
- `deps/davids-bikeshed-pure` — Pure Storage work config: the `bikeshed.pure` module, internal
  tooling packages, corporate agent memory and MCP servers
  ([bikeshed-pure](https://github.com/dszakallas/bikeshed-pure)).

Prefer adding generic functionality to `deps/davids-dotfiles-common`; keep host- and
user-specific wiring in this repo.

## Repository layout

```text
flake.nix                 # entrypoint: inputs, overlays, darwinConfigurations
devenv.nix / devenv.yaml  # dev shell, git hooks, agent MCP config
hosts/                    # per-machine configs (imported by mkDarwin)
modules/
  system/                 # unix-like (nixOS + darwin) modules
  darwin/                 # macOS-only modules
  home/                   # home-manager modules
overlays/                 # nixpkgs overlays (applied to all systems)
pkgs/                     # packages, built via callPackageWithRec
users/
  <user>/                 # user + home-manager wiring per host
  instructions/           # agent memory fragments (user.md, worktrees.md, tropes.md)
  skills/                 # agent skills (devenv, lang-cz, skill-creator, ...)
deps/                     # dependency flakes (see above)
```

Hosts and their primary users:

- `Jellyfish` (aarch64-darwin) — user `davidszakallas`
- `dszakallas--Clownfish` (aarch64-darwin) — user `dszakallas`

## Conventions

### Module signature

Modules take two argument sets: flake context first, then the nix-darwin/home-manager
module args. The common shape is:

```nix
{ self, davids-dotfiles-common, ... }:   # flake context (inputs // outputs)
{ pkgs, lib, config, ... }:              # module system args
{
  # options / config
}
```

Custom options live under the `davids.*` namespace (e.g. `davids.id`, `davids.agents`).
`deps/davids-bikeshed-pure` and `deps/bikeshed-homelab` own theirs under `bikeshed.*`
(`bikeshed.pure`, `bikeshed.jupiter`, `bikeshed.kolobok`); the git and SSH user presets
`bikeshed-homelab` declares still extend the `davids.git` tree owned by dotfiles-common.
Gate them behind `lib.mkEnableOption` and `lib.mkIf`.

### Directory imports

Directories are imported recursively by the `importRec` / `importRec1` / `callPackageWithRec`
helpers in `deps/davids-dotfiles-common/lib`. A "leaf" is a `.nix` file or a directory
containing `default.nix`; its basename becomes the attribute name. Adding a file under
`modules/*`, `overlays/`, `users/`, or `pkgs/` registers it automatically — there is no
manual list to update. Do not create both a `foo.nix` and a `foo/` in the same directory
(overlapping keys throw).

### Formatting and hooks

Enforced by pre-commit hooks (`devenv`'s `git-hooks`):

- `nixfmt` — all `.nix` files (except `pkgs/npm/_.*.nix`).
- `markdownlint` — max line length 120; `users/skills/*` excluded.
- `shellcheck` — shell scripts.

`.editorconfig` sets LF endings, trailing-whitespace trim, and a final newline; 2-space
indent for nix/shell/json/yaml/toml, tabs for gitconfig and host files.

## Commands

Run everything inside the devenv shell. If `DEVENV_CMDLINE` is set you are already in it;
otherwise prefix one-off commands:

```bash
devenv shell --no-tui --quiet -- <command>
```

- Check the flake: `nix flake check`
- Build/apply the current host: `darwin-rebuild switch --flake .#dszakallas--Clownfish`
  (use `.#Jellyfish` on the other machine).
- Build a specific package: `nix build .#<pkg>`
- Run tests (also what CI runs): `devenv test`

CI (`.github/workflows/ci.yaml`) initializes the `davids-dotfiles-common` submodule and runs
`devenv test` on every push.

## Local Dependency Development Workflow

This project uses Git submodules for local development of flake dependencies.

### Workflow

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

### Important Notes

- **Git Tracking**: Nix requires that changes in the submodule are at least staged (if using `path:`) or committed.
- **Nix Submodule Bug**: Due to a [known issue in Nix](https://github.com/NixOS/nix/issues/13324),
  changes in submodules might not be picked up if the parent repository is clean.
  - **Instruction**: Always ensure the parent repository is "dirty" (has unstaged/staged changes) when testing local
    submodule modifications. You can do this by adding a temporary comment or newline to a file in the root directory
    (e.g., `flake.nix` or `AGENTS.md`).
- **Submodule Testing**: When making changes in a dependency flake submodule (e.g.
  `deps/davids-dotfiles-common`), also `cd` into the dependency repository and run
  `devenv test` to verify that its own tests pass.

### Committing and Publishing Submodule Changes

Changes that span multiple repositories (this repo + submodules) require extra steps to publish correctly.

#### Commit order

1. **Commit inside the submodule first** (`deps/davids-dotfiles-common`, `deps/bikeshed-homelab`).
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

#### When submodule main branch moves forward

If the submodule's remote `main` advances (e.g. someone pushed new commits) while you have local commits on a
detached HEAD, your commits are not on `main` and will be lost when the submodule is updated. To avoid this:

- Work on the submodule with `git checkout main` before making changes, so commits land on the branch.
- After the submodule's remote advances, rebase your local work:

  ```bash
  cd deps/<name>
  git fetch origin
  git rebase origin/main
  git push origin main
  ```

- Then update the parent repo pointer as described above.
