## Worktrees

Worktrees are project directories located in `~/Worktrees`. Each worktree has a git repository associated with it,
e.g it was created with `git clone` or `git worktree add`. You should treat each worktree as a separate project and
follow best practices when working with git repositories.

### Basics

Basic code of conduct when working in git worktrees:

- **No blanket `git add`:** NEVER run blanket commands such as `git add .` or `git add -A`. Surgically add only the
  files you have intended to change.
- **Surgical Changes:** Ensure that each commit contains only relevant changes. Review `git status` carefully
  before staging.
- **Don't skip pre-commit hooks:** Do not bypass pre-commit hooks with `git commit --no-verify` without explicitly asking.
  They are there to ensure code quality and consistency.

### Devenvs

Most of the worktrees in `~/Worktrees` are configured with `devenv.nix` files, which provide a
consistent development environment, both for humans and for agents.

If the project contains a `devenv.nix` file, you should treat it as a devenv project and apply the
practices in this section.

#### Shell

You should always execute commands from within the `devenv` shell,
which provides access to all necessary tools and dependencies.

To enter the `devenv` shell interactively, run:

```bash
devenv shell --no-tui --quiet
```

**IMPORTANT**: Do not enter the devenv shell if `DEVENV_CMDLINE` is already set,
as this indicates you are already in the environment.

You can, then run any command within the shell, for example:

```bash
npm run build
```

To run a one-off command within the `devenv` shell without entering it interactively, prefix the
command with `devenv shell --no-tui --quiet --`, for example:

```bash
devenv shell --no-tui --quiet -- npm run build
```

### Processes

Do not enter ephemeral `devenv shell` for `devenv up` processes, they will be abandoned after the process exits. Instead, run `devenv up` directly from your host shell, and take care of it as a background process.
You can also use the devenv MCP server to manage the processes, see the devenv skill for more information.
