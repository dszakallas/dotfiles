#!/usr/bin/env bash
set -euo pipefail

expand_path() {
  local raw_path="$1"
  case "$raw_path" in
    \~)
      printf "%s" "$HOME"
      ;;
    \~/*)
      printf "%s/%s" "$HOME" "${raw_path#"~/"}"
      ;;
    *)
      printf "%s" "$raw_path"
      ;;
  esac
}

get_git_config_path() {
  local key
  for key in "$@"; do
    local val
    if val=$(git config --path --get "$key" 2>/dev/null) && [ -n "$val" ]; then
      printf "%s" "$val"
      return 0
    fi
  done
  return 1
}

resolve_repo_dir() {
  if [ -n "${GIT_OPERATOR_REPO_DIR:-}" ]; then
    expand_path "$GIT_OPERATOR_REPO_DIR"
    return 0
  fi
  local cfg_path
  if cfg_path=$(get_git_config_path "operator.repos" "operator.repodir" "operator.repoDir" "operator.repo-dir"); then
    printf "%s" "$cfg_path"
    return 0
  fi
  expand_path "$HOME/repos"
}

resolve_worktree_dir() {
  if [ -n "${GIT_OPERATOR_WORKTREE_DIR:-}" ]; then
    expand_path "$GIT_OPERATOR_WORKTREE_DIR"
    return 0
  fi
  local cfg_path
  if cfg_path=$(get_git_config_path "operator.worktrees" "operator.worktreedir" "operator.worktreeDir" "operator.worktree-dir"); then
    printf "%s" "$cfg_path"
    return 0
  fi
  expand_path "$HOME/worktrees"
}

get_init_worktree_hook() {
  local project_name="${1:-}"
  local hook_exec=""
  if [ -n "$project_name" ]; then
    hook_exec=$(git config --get "operator.hooks.$project_name.init_worktree.exec" 2>/dev/null || true)
  fi
  if [ -z "$hook_exec" ]; then
    hook_exec=$(git config --get 'operator.hooks.*.init_worktree.exec' 2>/dev/null || true)
  fi
  if [ -z "$hook_exec" ]; then
    hook_exec=$(git config --get 'operator.hooks.*.init-worktree.exec' 2>/dev/null || true)
  fi
  printf "%s" "$hook_exec"
}

run_init_worktree_hook() {
  local project_name="$1"
  local wt_name="$2"
  local target_worktree="$3"
  local target_repo="$4"

  local hook_exec
  hook_exec=$(get_init_worktree_hook "$project_name")
  if [ -z "$hook_exec" ]; then
    return 0
  fi

  echo "Executing init_worktree hook..."
  (
    cd "$target_worktree"
    export REPO_NAME="$project_name"
    export WORKTREE_NAME="$wt_name"
    export GIT_OPERATOR_REPO_NAME="$project_name"
    export GIT_OPERATOR_WORKTREE_NAME="$wt_name"
    export GIT_OPERATOR_WORKTREE_PATH="$target_worktree"
    export GIT_OPERATOR_REPO_PATH="$target_repo"
    bash -c "$hook_exec"
  )
}

cmd_create() {
  if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
    echo "error: create requires <remote-url> and <project-name>" >&2
    echo "usage: git operator create <remote-url> <project-name>" >&2
    return 1
  fi

  local remote_url="$1"
  local project_name="${2%.git}"
  local target_repo="$REPO_DIR/${project_name}.git"

  if [ -d "$target_repo" ]; then
    echo "error: repository already exists at '$target_repo'" >&2
    return 1
  fi

  echo "Cloning bare repository to '$target_repo'..."
  git clone --bare "$remote_url" "$target_repo"

  echo "Configuring fetch refspec..."
  (
    cd "$target_repo"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    echo "Fetching remote branches..."
    git fetch
    git remote set-head origin --auto 2>/dev/null || true
  )

  echo "Successfully created bare repository at '$target_repo'."
}

cmd_delete() {
  if [ $# -lt 1 ] || [ -z "$1" ]; then
    echo "error: delete requires <project-name>" >&2
    echo "usage: git operator delete <project-name>" >&2
    return 1
  fi

  local project_name="${1%.git}"
  local target_repo="$REPO_DIR/${project_name}.git"

  if [ ! -d "$target_repo" ]; then
    echo "error: bare repository does not exist at '$target_repo'" >&2
    return 1
  fi

  local target_repo_canonical
  target_repo_canonical=$(cd "$target_repo" && pwd -P)

  echo "Discovering active worktrees for '$project_name'..."
  local wt_dirs=()
  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        local wt_dir="${line#worktree }"
        local wt_canonical=""
        if [ -d "$wt_dir" ]; then
          wt_canonical=$(cd "$wt_dir" 2>/dev/null && pwd -P || true)
        fi
        if [ -n "$wt_canonical" ] && [ "$wt_canonical" = "$target_repo_canonical" ]; then
          continue
        fi
        if [ "$wt_dir" = "$target_repo" ]; then
          continue
        fi
        wt_dirs+=("$wt_dir")
        ;;
    esac
  done < <(cd "$target_repo" && git worktree list --porcelain)

  for wt_dir in "${wt_dirs[@]}"; do
    if [ -n "$wt_dir" ] && [ "$wt_dir" != "/" ] && [ "$wt_dir" != "$HOME" ]; then
      echo "Deleting worktree: '$wt_dir'"
      rm -rf "$wt_dir"
    fi
  done

  echo "Deleting bare repository: '$target_repo'"
  rm -rf "$target_repo"
  echo "Successfully deleted '$project_name' repository and associated worktrees."
}

cmd_worktree_add() {
  if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
    echo "error: worktree add requires <project-name> and <wt-name>" >&2
    echo "usage: git operator worktree add <project-name> <wt-name> [start-point]" >&2
    return 1
  fi

  local project_name="${1%.git}"
  local wt_name="$2"
  local start_point="${3:-}"
  local target_repo="$REPO_DIR/${project_name}.git"
  local target_worktree="$WORKTREE_DIR/$wt_name"

  if [ ! -d "$target_repo" ]; then
    echo "error: bare repository does not exist at '$target_repo'" >&2
    return 1
  fi

  if [ -e "$target_worktree" ]; then
    echo "error: worktree path already exists at '$target_worktree'" >&2
    return 1
  fi

  (
    cd "$target_repo"
    if [ -n "$start_point" ]; then
      if git rev-parse --verify --quiet "refs/heads/$wt_name" >/dev/null; then
        echo "Branch '$wt_name' already exists. Adding worktree attached to existing branch..."
        git worktree add "$target_worktree" "$wt_name"
      else
        git worktree add -b "$wt_name" "$target_worktree" "$start_point"
      fi
    else
      # No start-point provided: use worktree name, creating branch if necessary
      if git rev-parse --verify --quiet "refs/heads/$wt_name" >/dev/null; then
        echo "Branch '$wt_name' already exists. Checking out into worktree..."
        git worktree add "$target_worktree" "$wt_name"
      elif git rev-parse --verify --quiet "refs/remotes/origin/$wt_name" >/dev/null; then
        echo "Branch '$wt_name' found on origin. Tracking remote branch..."
        git worktree add -b "$wt_name" "$target_worktree" "origin/$wt_name"
      else
        echo "Creating new branch '$wt_name'..."
        git worktree add -b "$wt_name" "$target_worktree"
      fi
    fi
  )

  run_init_worktree_hook "$project_name" "$wt_name" "$target_worktree" "$target_repo"
}

cmd_worktree_remove() {
  local force=false
  local positional_args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force)
        force=true
        shift
        ;;
      *)
        positional_args+=("$1")
        shift
        ;;
    esac
  done

  if [ ${#positional_args[@]} -lt 2 ] || [ -z "${positional_args[0]}" ] || [ -z "${positional_args[1]}" ]; then
    echo "error: worktree remove requires <project-name> and <wt-name>" >&2
    echo "usage: git operator worktree remove [-f|--force] <project-name> <wt-name>" >&2
    return 1
  fi

  local project_name="${positional_args[0]%.git}"
  local wt_name="${positional_args[1]}"
  local target_repo="$REPO_DIR/${project_name}.git"
  local target_worktree="$WORKTREE_DIR/$wt_name"

  if [ ! -d "$target_repo" ]; then
    echo "error: bare repository does not exist at '$target_repo'" >&2
    return 1
  fi

  if [ ! -d "$target_worktree" ]; then
    echo "error: worktree directory does not exist at '$target_worktree'" >&2
    return 1
  fi

  (
    cd "$target_repo"
    if [ "$force" = true ]; then
      git worktree remove --force "$target_worktree"
    else
      git worktree remove "$target_worktree"
    fi
  )
}

cmd_worktree_list() {
  if [ $# -lt 1 ] || [ -z "$1" ]; then
    echo "error: worktree list requires <project-name>" >&2
    echo "usage: git operator worktree list <project-name>" >&2
    return 1
  fi

  local project_name="${1%.git}"
  local target_repo="$REPO_DIR/${project_name}.git"

  if [ ! -d "$target_repo" ]; then
    echo "error: bare repository does not exist at '$target_repo'" >&2
    return 1
  fi

  (
    cd "$target_repo"
    git worktree list "$@"
  )
}

usage() {
  cat <<'EOF'
git-operator - Automate bare repositories and isolated agent worktrees

Usage:
  git operator create <remote-url> <project-name>
  git operator delete <project-name>
  git operator worktree add <project-name> <wt-name> [start-point]
  git operator worktree remove [-f|--force] <project-name> <wt-name>
  git operator worktree list <project-name>

Configuration (in order of precedence):
  1. Environment variables:
       GIT_OPERATOR_REPO_DIR       Path to bare repositories directory
       GIT_OPERATOR_WORKTREE_DIR   Path to worktrees directory
  2. Git configuration [operator] section:
       git config operator.repos <path>
       git config operator.worktrees <path>
  3. Defaults:
       repos:     ~/repos
       worktrees: ~/worktrees
EOF
}

main() {
  if [ $# -lt 1 ]; then
    usage >&2
    exit 1
  fi

  REPO_DIR=$(resolve_repo_dir)
  WORKTREE_DIR=$(resolve_worktree_dir)
  mkdir -p "$REPO_DIR" "$WORKTREE_DIR"

  local cmd="$1"
  shift

  case "$cmd" in
    create)
      cmd_create "$@"
      ;;
    delete)
      cmd_delete "$@"
      ;;
    worktree)
      if [ $# -lt 1 ]; then
        echo "error: missing worktree subcommand (add, remove, list)" >&2
        usage >&2
        exit 1
      fi
      local subcmd="$1"
      shift
      case "$subcmd" in
        add)
          cmd_worktree_add "$@"
          ;;
        remove|rm)
          cmd_worktree_remove "$@"
          ;;
        list|ls)
          cmd_worktree_list "$@"
          ;;
        *)
          echo "error: unknown worktree subcommand '$subcmd'" >&2
          usage >&2
          exit 1
          ;;
      esac
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown command '$cmd'" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
