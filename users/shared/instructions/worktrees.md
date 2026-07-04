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
