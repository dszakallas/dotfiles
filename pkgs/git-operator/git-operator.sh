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

validate_path_component() {
  local kind="$1"
  local name="$2"

  case "$name" in
    ""|.|..|-*|*/*|*\\*|*$'\n'*|*$'\r'*)
      echo "error: invalid $kind '$name'" >&2
      return 1
      ;;
  esac
}

validate_worktree_name() {
  local wt_name="$1"

  validate_path_component "worktree name" "$wt_name"
  if ! git check-ref-format --branch "$wt_name" >/dev/null 2>&1; then
    echo "error: invalid worktree branch name '$wt_name'" >&2
    return 1
  fi
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

parse_initial_worktree_options() {
  INITIAL_NO_WORKTREE=false
  INITIAL_WORKTREE_NAME=""
  INITIAL_POSITIONAL_ARGS=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --no-worktree)
        if [ "$INITIAL_NO_WORKTREE" = true ]; then
          echo "error: --no-worktree may only be specified once" >&2
          return 1
        fi
        INITIAL_NO_WORKTREE=true
        shift
        ;;
      --worktree-name)
        if [ $# -lt 2 ] || [ -z "$2" ]; then
          echo "error: --worktree-name requires a value" >&2
          return 1
        fi
        INITIAL_WORKTREE_NAME="$2"
        shift 2
        ;;
      --worktree-name=*)
        INITIAL_WORKTREE_NAME="${1#--worktree-name=}"
        if [ -z "$INITIAL_WORKTREE_NAME" ]; then
          echo "error: --worktree-name requires a value" >&2
          return 1
        fi
        shift
        ;;
      --)
        shift
        INITIAL_POSITIONAL_ARGS+=("$@")
        break
        ;;
      -*)
        echo "error: unknown option '$1'" >&2
        return 1
        ;;
      *)
        INITIAL_POSITIONAL_ARGS+=("$1")
        shift
        ;;
    esac
  done

  if [ "$INITIAL_NO_WORKTREE" = true ] && [ -n "$INITIAL_WORKTREE_NAME" ]; then
    echo "error: --no-worktree and --worktree-name cannot be used together" >&2
    return 1
  fi
}

cmd_clone() {
  parse_initial_worktree_options "$@" || return 1
  if [ ${#INITIAL_POSITIONAL_ARGS[@]} -ne 2 ] || [ -z "${INITIAL_POSITIONAL_ARGS[0]}" ] || [ -z "${INITIAL_POSITIONAL_ARGS[1]}" ]; then
    echo "error: clone requires <remote-url> and <project-name>" >&2
    echo "usage: git operator clone [--no-worktree | --worktree-name <name>] <remote-url> <project-name>" >&2
    return 1
  fi

  local remote_url="${INITIAL_POSITIONAL_ARGS[0]}"
  local project_name="${INITIAL_POSITIONAL_ARGS[1]%.git}"
  validate_path_component "project name" "$project_name"
  local target_repo="$REPO_DIR/${project_name}.git"
  local wt_name="${INITIAL_WORKTREE_NAME:-$project_name}"
  local target_worktree="$WORKTREE_DIR/$wt_name"

  if [ -e "$target_repo" ]; then
    echo "error: repository path already exists at '$target_repo'" >&2
    return 1
  fi

  if [ "$INITIAL_NO_WORKTREE" = false ]; then
    validate_path_component "worktree name" "$wt_name"
    if [ -e "$target_worktree" ]; then
      echo "error: worktree path already exists at '$target_worktree'" >&2
      return 1
    fi
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

  if [ "$INITIAL_NO_WORKTREE" = true ]; then
    echo "Successfully cloned bare repository at '$target_repo'."
    return 0
  fi

  echo "Creating initial worktree at '$target_worktree'..."
  if git -C "$target_repo" rev-parse --verify --quiet HEAD >/dev/null; then
    local initial_branch
    if ! initial_branch=$(git -C "$target_repo" symbolic-ref --quiet --short HEAD); then
      echo "error: could not determine the remote default branch" >&2
      return 1
    fi
    git -C "$target_repo" branch --set-upstream-to="origin/$initial_branch" "$initial_branch"
    git -C "$target_repo" worktree add "$target_worktree" "$initial_branch"
  else
    git -C "$target_repo" worktree add --orphan -b main "$target_worktree"
  fi

  echo "Successfully cloned '$project_name' with worktree at '$target_worktree'."
}

cmd_init() {
  parse_initial_worktree_options "$@" || return 1
  if [ ${#INITIAL_POSITIONAL_ARGS[@]} -ne 1 ] || [ -z "${INITIAL_POSITIONAL_ARGS[0]}" ]; then
    echo "error: init requires <project-name>" >&2
    echo "usage: git operator init [--no-worktree | --worktree-name <name>] <project-name>" >&2
    return 1
  fi

  local project_name="${INITIAL_POSITIONAL_ARGS[0]%.git}"
  validate_path_component "project name" "$project_name"
  local target_repo="$REPO_DIR/${project_name}.git"
  local wt_name="${INITIAL_WORKTREE_NAME:-$project_name}"
  local target_worktree="$WORKTREE_DIR/$wt_name"

  if [ -e "$target_repo" ]; then
    echo "error: repository path already exists at '$target_repo'" >&2
    return 1
  fi

  if [ "$INITIAL_NO_WORKTREE" = false ]; then
    validate_path_component "worktree name" "$wt_name"
    if [ -e "$target_worktree" ]; then
      echo "error: worktree path already exists at '$target_worktree'" >&2
      return 1
    fi
  fi

  echo "Initializing bare repository at '$target_repo'..."
  git init --bare --initial-branch=main "$target_repo"

  if [ "$INITIAL_NO_WORKTREE" = true ]; then
    echo "Successfully initialized bare repository at '$target_repo'."
    return 0
  fi

  echo "Creating initial worktree at '$target_worktree'..."
  (
    cd "$target_repo"
    git worktree add --orphan -b main "$target_worktree"
  )

  echo "Successfully initialized '$project_name' with worktree at '$target_worktree'."
}

cmd_delete() {
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

  if [ ${#positional_args[@]} -ne 1 ] || [ -z "${positional_args[0]}" ]; then
    echo "error: delete requires <project-name>" >&2
    echo "usage: git operator delete [-f|--force] <project-name>" >&2
    return 1
  fi

  local project_name="${positional_args[0]%.git}"
  validate_path_component "project name" "$project_name"
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

  if [ ${#wt_dirs[@]} -gt 0 ] && [ "$force" = false ]; then
    echo "error: repository has active worktrees; rerun with --force to remove them" >&2
    return 1
  fi

  if [ "$force" = true ]; then
    for wt_dir in "${wt_dirs[@]}"; do
      echo "Removing worktree: '$wt_dir'"
      (
        cd "$target_repo"
        git worktree remove --force "$wt_dir"
      )
    done
  fi

  (
    cd "$target_repo"
    git worktree prune
  )

  echo "Deleting bare repository: '$target_repo'"
  rm -rf "$target_repo"
  echo "Successfully deleted '$project_name' repository and associated worktrees."
}

cmd_worktree_add() {
  local fetch=false
  local positional_args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --fetch)
        fetch=true
        shift
        ;;
      *)
        positional_args+=("$1")
        shift
        ;;
    esac
  done

  if [ ${#positional_args[@]} -lt 2 ] || [ ${#positional_args[@]} -gt 3 ] || [ -z "${positional_args[0]}" ] || [ -z "${positional_args[1]}" ]; then
    echo "error: worktree add requires <project-name> and <wt-name>" >&2
    echo "usage: git operator worktree add [--fetch] <project-name> <wt-name> [start-point]" >&2
    return 1
  fi

  local project_name="${positional_args[0]%.git}"
  local wt_name="${positional_args[1]}"
  local start_point="${positional_args[2]:-}"
  validate_path_component "project name" "$project_name"
  validate_worktree_name "$wt_name"
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

  if [ -n "$start_point" ] && git -C "$target_repo" rev-parse --verify --quiet "refs/heads/$wt_name" >/dev/null; then
    echo "error: branch '$wt_name' already exists; omit the start point to attach it or choose a new worktree name" >&2
    return 1
  fi

  (
    cd "$target_repo"
    if [ "$fetch" = true ]; then
      echo "Fetching remote branches..."
      git fetch --prune origin
    fi

    if [ -n "$start_point" ]; then
      git worktree add -b "$wt_name" "$target_worktree" "$start_point"
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
  validate_path_component "project name" "$project_name"
  validate_worktree_name "$wt_name"
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
  validate_path_component "project name" "$project_name"
  local target_repo="$REPO_DIR/${project_name}.git"

  if [ ! -d "$target_repo" ]; then
    echo "error: bare repository does not exist at '$target_repo'" >&2
    return 1
  fi

  (
    cd "$target_repo"
    git worktree list
  )
}

cmd_get_reponame() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: not inside a git worktree" >&2
    return 1
  fi

  local toplevel
  toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$toplevel" ]; then
    echo "error: unable to determine worktree top-level" >&2
    return 1
  fi

  if [ -d "$toplevel/.git" ]; then
    basename "$toplevel"
  elif [ -f "$toplevel/.git" ]; then
    local common_dir
    common_dir=$(cd "$toplevel" && cd "$(git rev-parse --git-common-dir)" && pwd -P)
    if [ "$(git --git-dir="$common_dir" rev-parse --is-bare-repository 2>/dev/null)" = "true" ]; then
      local repo_name
      repo_name=$(basename "$common_dir")
      echo "${repo_name%.git}"
    else
      basename "$(dirname "$common_dir")"
    fi
  else
    echo "error: unknown git layout in $toplevel" >&2
    return 1
  fi
}

usage() {
  cat <<'EOF'
git-operator - Automate bare repositories and isolated agent worktrees

Usage:
  git operator clone [--no-worktree | --worktree-name <name>] <remote-url> <project-name>
  git operator init [--no-worktree | --worktree-name <name>] <project-name>
  git operator delete [-f|--force] <project-name>
  git operator worktree add [--fetch] <project-name> <wt-name> [start-point]
  git operator worktree remove [-f|--force] <project-name> <wt-name>
  git operator worktree list <project-name>
  git operator get-reponame

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
    clone)
      cmd_clone "$@"
      ;;
    init)
      cmd_init "$@"
      ;;
    delete)
      cmd_delete "$@"
      ;;
    get-reponame)
      cmd_get_reponame "$@"
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
