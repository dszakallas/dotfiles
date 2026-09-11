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

canonical_dir() {
  (cd "$1" 2>/dev/null && pwd -P)
}

# GNU stat spells this -c, BSD stat spells it -f. Try GNU first: BSD stat has
# no -c and fails cleanly, while GNU's -f means something else entirely.
device_id() {
  stat -c '%d' "$1" 2>/dev/null || stat -f '%d' "$1" 2>/dev/null
}

read_gitdir_pointer() {
  local line
  line=$(head -n1 "$1" 2>/dev/null) || return 1
  case "$line" in
    gitdir:\ *)
      printf "%s" "${line#gitdir: }"
      ;;
    *)
      return 1
      ;;
  esac
}

# Derive the project name from the basename of the origin fetch URL, accepting
# both scp-style and URL-style remotes.
derive_project_name() {
  local url="$1"
  url="${url%/}"
  url="${url%.git}"
  url="${url##*/}"
  url="${url##*:}"
  [ -n "$url" ] || return 1
  printf "%s" "$url"
}

# The primary worktree is the first entry git reports for the repository.
resolve_primary_worktree() {
  local listing line
  listing=$(git -C "$1" worktree list --porcelain 2>/dev/null) || return 1
  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        printf "%s" "${line#worktree }"
        return 0
        ;;
    esac
  done <<EOF
$listing
EOF
  return 1
}

migrate_error() {
  MIGRATE_ERRORS+=("$1")
  echo "error: $1" >&2
}

migrate_warn() {
  MIGRATE_WARNINGS+=("$1")
  echo "warning: $1" >&2
}

# Records every submodule checkout together with the absolute git directory it
# currently points at, so the pointers can be rewritten after the move.
collect_submodule_fixups() {
  local sup_wt="$1"
  [ -f "$sup_wt/.gitmodules" ] || return 0

  local line sub_path sub_wt pointer target
  while IFS= read -r line; do
    sub_path="${line#* }"
    [ -n "$sub_path" ] || continue
    sub_wt="$sup_wt/$sub_path"
    [ -f "$sub_wt/.git" ] || continue
    pointer=$(read_gitdir_pointer "$sub_wt/.git") || continue
    target=$(cd "$sub_wt" && cd "$pointer" 2>/dev/null && pwd -P) || continue
    [ -n "$target" ] || continue
    SUBMODULE_FIXUPS+=("$sub_wt|$target")
    collect_submodule_fixups "$sub_wt"
  done < <(git config -f "$sup_wt/.gitmodules" --get-regexp '^submodule\..*\.path$' 2>/dev/null || true)
}

# Remembers a .git file before it is overwritten so rollback can restore it.
backup_git_file() {
  local path="$1"
  if [ -f "$path" ]; then
    GITFILE_BACKUPS+=("$path|$(cat "$path")")
  else
    GITFILE_BACKUPS+=("$path|")
  fi
}

copy_tree() {
  local src="$1" dst="$2"
  cp -Rc "$src" "$dst" 2>/dev/null \
    || cp -R --reflink=auto "$src" "$dst" 2>/dev/null \
    || cp -R "$src" "$dst"
}

# Picks the branch the bare repository's own HEAD should point at.
pick_default_branch() {
  local wt="$1" branch

  if branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null) && [ -n "$branch" ]; then
    printf "%s" "$branch"
    return 0
  fi
  if branch=$(git -C "$wt" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) && [ -n "$branch" ]; then
    printf "%s" "${branch#origin/}"
    return 0
  fi
  for branch in main master; do
    if git -C "$wt" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
      printf "%s" "$branch"
      return 0
    fi
  done
  return 1
}

# Builds PLAN_PRIMARY, PLAN_PROJECT and PLAN_WORKTREES for the repository
# reached through <path>. Returns 0 when it is ready to migrate, 1 on error and
# 2 when it should be skipped without failing the run.
plan_migration() {
  local path="$1"
  local explicit_project="${2:-}"

  PLAN_PRIMARY=""
  PLAN_PROJECT=""
  PLAN_WORKTREES=()

  local canon
  canon=$(canonical_dir "$path") || true
  if [ -z "$canon" ]; then
    migrate_error "$path: no such directory"
    return 1
  fi

  if [ ! -e "$canon/.git" ]; then
    migrate_warn "$canon: not a git repository; skipped"
    return 2
  fi

  if [ -L "$canon/.git" ]; then
    migrate_error "$canon: .git is a symlink; resolve it before migrating"
    return 1
  fi

  if [ -f "$canon/.git" ]; then
    local pointer
    if ! pointer=$(read_gitdir_pointer "$canon/.git"); then
      migrate_error "$canon: unreadable .git file"
      return 1
    fi
    if [ ! -e "$pointer" ]; then
      migrate_error "$canon: orphaned worktree; its repository '$pointer' no longer exists"
      return 1
    fi
  fi

  # Rule 1, applied to the path that was named.
  if [ "$(dirname "$canon")" != "$WORKTREE_DIR_CANON" ]; then
    migrate_error "$canon: not a direct child of '$WORKTREE_DIR'
  move it under '$WORKTREE_DIR' and retry"
    return 1
  fi

  local common_dir
  if ! common_dir=$(git -C "$canon" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
    migrate_error "$canon: not usable as a git worktree"
    return 1
  fi
  common_dir=$(canonical_dir "$common_dir")

  case "$common_dir" in
    "$REPO_DIR_CANON"/*)
      migrate_warn "$canon: already managed by git operator; skipped"
      return 2
      ;;
  esac

  if [ "$(git -C "$canon" rev-parse --is-bare-repository 2>/dev/null)" = "true" ]; then
    migrate_warn "$canon: bare repository; skipped"
    return 2
  fi

  local primary
  if ! primary=$(resolve_primary_worktree "$canon"); then
    migrate_error "$canon: unable to resolve its repository"
    return 1
  fi
  primary=$(canonical_dir "$primary") || true

  # Rule 2.
  if [ "$primary" != "$canon" ]; then
    migrate_error "$canon: not a primary worktree; its repository is '$primary'
  run: git operator migrate '$primary'"
    return 1
  fi

  # Rule 1, applied to every worktree in the family.
  local listing line wt wt_canon
  local candidates=()
  local misplaced=()
  local missing=()
  listing=$(git -C "$canon" worktree list --porcelain)
  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        wt="${line#worktree }"
        wt_canon=$(canonical_dir "$wt") || true
        if [ -z "$wt_canon" ]; then
          missing+=("$wt")
          continue
        fi
        if [ "$(dirname "$wt_canon")" != "$WORKTREE_DIR_CANON" ]; then
          misplaced+=("$wt_canon")
          continue
        fi
        candidates+=("$wt_canon")
        ;;
    esac
  done <<EOF
$listing
EOF

  if [ ${#misplaced[@]} -gt 0 ] || [ ${#missing[@]} -gt 0 ]; then
    local message="$canon: cannot migrate this repository as it stands"
    if [ ${#misplaced[@]} -gt 0 ]; then
      message="$message
  worktrees outside '$WORKTREE_DIR':"
      for wt in "${misplaced[@]}"; do
        message="$message
    $wt"
      done
      message="$message
  move them under '$WORKTREE_DIR' with 'git worktree move' and retry"
    fi
    if [ ${#missing[@]} -gt 0 ]; then
      message="$message
  registered worktrees whose directory is gone:"
      for wt in "${missing[@]}"; do
        message="$message
    $wt"
      done
      message="$message
  drop them with 'git -C $canon worktree prune' and retry"
    fi
    migrate_error "$message"
    return 1
  fi

  if [ -n "$explicit_project" ]; then
    PLAN_PROJECT="$explicit_project"
  else
    local url
    if ! url=$(git -C "$canon" remote get-url origin 2>/dev/null) || [ -z "$url" ]; then
      migrate_error "$canon: no 'origin' remote; rerun with --project-name <name>"
      return 1
    fi
    if ! PLAN_PROJECT=$(derive_project_name "$url"); then
      migrate_error "$canon: cannot derive a project name from origin '$url'; rerun with --project-name <name>"
      return 1
    fi
  fi

  if ! validate_path_component "project name" "$PLAN_PROJECT" 2>/dev/null; then
    migrate_error "$canon: derived project name '$PLAN_PROJECT' is not a valid path component; rerun with --project-name <name>"
    return 1
  fi

  local bare="$REPO_DIR/${PLAN_PROJECT}.git"
  if [ -e "$bare" ]; then
    migrate_error "$canon: '$bare' already exists; rerun with --project-name <name>"
    return 1
  fi

  local claimed
  for claimed in "${MIGRATE_CLAIMED_PROJECTS[@]}"; do
    if [ "$claimed" = "$PLAN_PROJECT" ]; then
      migrate_error "$canon: project name '$PLAN_PROJECT' is already claimed by another repository in this run; rerun with --project-name <name>"
      return 1
    fi
  done

  # Remaining preflight, per worktree.
  local git_dir marker
  for wt in "${candidates[@]}"; do
    if ! validate_path_component "worktree name" "$(basename "$wt")" 2>/dev/null; then
      migrate_error "$wt: invalid worktree directory name"
      return 1
    fi
    git_dir=$(git -C "$wt" rev-parse --absolute-git-dir)
    for marker in rebase-merge rebase-apply CHERRY_PICK_HEAD MERGE_HEAD REVERT_HEAD BISECT_LOG; do
      if [ -e "$git_dir/$marker" ]; then
        migrate_error "$wt: operation in progress ($marker); finish or abort it first"
        return 1
      fi
    done
  done

  if [ "$(device_id "$canon/.git")" != "$(device_id "$REPO_DIR")" ]; then
    migrate_error "$canon: '$REPO_DIR' is on a different filesystem; the move must be a rename"
    return 1
  fi

  if ! pick_default_branch "$canon" >/dev/null; then
    migrate_error "$canon: cannot determine a default branch for the bare repository"
    return 1
  fi

  PLAN_PRIMARY="$canon"
  PLAN_WORKTREES=("${candidates[@]}")
  MIGRATE_CLAIMED_PROJECTS+=("$PLAN_PROJECT")
}

print_migration_plan() {
  local primary="$1" project="$2"
  shift 2
  local wt
  echo "migrate $primary"
  echo "  project:   $project"
  echo "  bare repo: $REPO_DIR/${project}.git"
  echo "  worktrees:"
  for wt in "$@"; do
    echo "    $wt"
  done
}

migrate_rollback() {
  local entry path value src dst

  echo "Rolling back '$MIG_PRIMARY'..." >&2

  for entry in "${MIG_SUBMODULE_CONFIG[@]}"; do
    path="${entry%%|*}"
    value="${entry#*|}"
    if [ -n "$value" ]; then
      git config -f "$path/config" core.worktree "$value" 2>/dev/null || true
    else
      git config -f "$path/config" --unset core.worktree 2>/dev/null || true
    fi
  done

  for entry in "${GITFILE_BACKUPS[@]}"; do
    path="${entry%%|*}"
    value="${entry#*|}"
    if [ -n "$value" ]; then
      printf "%s\n" "$value" > "$path"
    else
      rm -f "$path"
    fi
  done

  local i
  for (( i=${#MIG_MOVED[@]}-1; i>=0; i-- )); do
    dst="${MIG_MOVED[$i]%%|*}"
    src="${MIG_MOVED[$i]#*|}"
    if [ -e "$dst" ]; then
      mkdir -p "$(dirname "$src")"
      mv "$dst" "$src"
    fi
  done

  if [ -n "$MIG_ADMIN_DIR" ] && [ -d "$MIG_ADMIN_DIR" ]; then
    rm -rf "$MIG_ADMIN_DIR"
    rmdir "$MIG_BARE/worktrees" 2>/dev/null || true
  fi

  if [ "$MIG_MOVED_GITDIR" = true ] && [ -d "$MIG_BARE" ]; then
    git config -f "$MIG_BARE/config" core.bare false 2>/dev/null || true
    mv "$MIG_BARE" "$MIG_PRIMARY/.git"
  fi

  echo "Rolled back '$MIG_PRIMARY'." >&2
}

migrate_move() {
  local src="$1" dst="$2"
  mv "$src" "$dst"
  MIG_MOVED+=("$dst|$src")
}

migrate_execute() {
  local primary="$1" project="$2"
  shift 2
  local worktrees=("$@")

  local bare="$REPO_DIR/${project}.git"
  local admin_name
  admin_name=$(basename "$primary")
  local admin_dir="$bare/worktrees/$admin_name"
  local old_git_dir
  old_git_dir=$(canonical_dir "$primary/.git")

  MIG_PRIMARY="$primary"
  MIG_BARE="$bare"
  MIG_ADMIN_DIR=""
  MIG_MOVED=()
  MIG_MOVED_GITDIR=false
  MIG_SUBMODULE_CONFIG=()
  GITFILE_BACKUPS=()
  SUBMODULE_FIXUPS=()

  # Snapshot what the verification pass will compare against, and collect the
  # submodule pointers while they still resolve.
  local wt
  local before_heads=()
  for wt in "${worktrees[@]}"; do
    before_heads+=("$(git -C "$wt" rev-parse HEAD 2>/dev/null || echo none)")
    collect_submodule_fixups "$wt"
  done
  local before_stashes before_branches default_branch
  before_stashes=$(git -C "$primary" stash list | wc -l | tr -d ' ')
  before_branches=$(git -C "$primary" for-each-ref --format='x' refs/heads | wc -l | tr -d ' ')
  default_branch=$(pick_default_branch "$primary")

  if [ "$MIGRATE_KEEP_BACKUP" = true ]; then
    echo "Backing up '$primary/.git'..."
    mkdir -p "$REPO_DIR/.migrate-backup"
    copy_tree "$primary/.git" "$REPO_DIR/.migrate-backup/${project}.git"
  fi

  echo "Moving '$primary/.git' to '$bare'..."
  mv "$primary/.git" "$bare"
  MIG_MOVED_GITDIR=true

  # Build the primary worktree's administrative directory. HEAD is copied
  # rather than moved: without it the bare repository stops being a git
  # directory and every later command fails.
  mkdir -p "$admin_dir"
  MIG_ADMIN_DIR="$admin_dir"
  cp "$bare/HEAD" "$admin_dir/HEAD"

  local file
  for file in index ORIG_HEAD COMMIT_EDITMSG MERGE_MSG; do
    if [ -e "$bare/$file" ]; then
      migrate_move "$bare/$file" "$admin_dir/$file"
    fi
  done
  if [ -e "$bare/logs/HEAD" ]; then
    mkdir -p "$admin_dir/logs"
    migrate_move "$bare/logs/HEAD" "$admin_dir/logs/HEAD"
  fi
  if [ -e "$bare/info/sparse-checkout" ]; then
    mkdir -p "$admin_dir/info"
    migrate_move "$bare/info/sparse-checkout" "$admin_dir/info/sparse-checkout"
  fi

  printf "../..\n" > "$admin_dir/commondir"
  printf "%s\n" "$primary/.git" > "$admin_dir/gitdir"
  backup_git_file "$primary/.git"
  printf "gitdir: %s\n" "$admin_dir" > "$primary/.git"

  # File-scoped until the repository is coherent again: a stale core.worktree
  # makes git chdir into a path that no longer exists.
  git config -f "$bare/config" core.bare true
  git config -f "$bare/config" --unset core.worktree 2>/dev/null || true
  git --git-dir="$bare" symbolic-ref HEAD "refs/heads/$default_branch"

  # Repoint the worktrees that were already linked. Their gitdir files still
  # hold the correct checkout paths, so each one names the file to rewrite.
  local dir pointer
  for dir in "$bare"/worktrees/*/; do
    dir="${dir%/}"
    [ "$dir" = "$admin_dir" ] && continue
    [ -f "$dir/gitdir" ] || continue
    pointer=$(head -n1 "$dir/gitdir")
    [ -n "$pointer" ] || continue
    [ -d "$(dirname "$pointer")" ] || continue
    backup_git_file "$pointer"
    printf "gitdir: %s\n" "$dir" > "$pointer"
  done

  # Submodule .git files and core.worktree are relative to the superproject, so
  # they all break the moment the git directory moves.
  local entry sub_wt old_target new_target previous
  for entry in "${SUBMODULE_FIXUPS[@]}"; do
    sub_wt="${entry%%|*}"
    old_target="${entry#*|}"
    case "$old_target" in
      "$old_git_dir"/*)
        new_target="$bare/${old_target#"$old_git_dir"/}"
        ;;
      *)
        continue
        ;;
    esac
    [ -d "$new_target" ] || continue
    backup_git_file "$sub_wt/.git"
    printf "gitdir: %s\n" "$new_target" > "$sub_wt/.git"
    # File-scoped: --git-dir would try to chdir into the now-stale
    # core.worktree before writing, and fail before it ever gets there.
    previous=$(git config -f "$new_target/config" core.worktree 2>/dev/null || true)
    MIG_SUBMODULE_CONFIG+=("$new_target|$previous")
    git config -f "$new_target/config" core.worktree "$sub_wt"
  done

  git -C "$bare" worktree repair "${worktrees[@]}" || true
  git -C "$bare" worktree prune

  # Verification. Any failure rolls the repository back to where it started.
  local index=0 failure=""
  for wt in "${worktrees[@]}"; do
    if ! git -C "$wt" status --porcelain >/dev/null 2>&1; then
      failure="$wt: git status failed after migration"
      break
    fi
    if [ "$(git -C "$wt" rev-parse HEAD 2>/dev/null || echo none)" != "${before_heads[$index]}" ]; then
      failure="$wt: HEAD changed during migration"
      break
    fi
    if [ -f "$wt/.gitmodules" ] && git -C "$wt" submodule status 2>&1 | grep -q '^fatal:'; then
      failure="$wt: submodules are broken after migration"
      break
    fi
    index=$((index + 1))
  done

  if [ -z "$failure" ]; then
    if [ "$(git -C "$primary" stash list | wc -l | tr -d ' ')" != "$before_stashes" ]; then
      failure="$primary: stash count changed during migration"
    elif [ "$(git -C "$primary" for-each-ref --format='x' refs/heads | wc -l | tr -d ' ')" != "$before_branches" ]; then
      failure="$primary: branch count changed during migration"
    elif ! git --git-dir="$bare" rev-parse --verify --quiet HEAD >/dev/null; then
      failure="$bare: HEAD does not resolve"
    elif [ "$MIGRATE_FSCK" = true ] && ! git --git-dir="$bare" fsck --connectivity-only --no-progress >/dev/null 2>&1; then
      failure="$bare: fsck reported problems"
    fi
  fi

  if [ -n "$failure" ]; then
    migrate_error "$failure"
    migrate_rollback
    return 1
  fi

  echo "Migrated '$primary' to '$bare'."
}

# Maps each candidate directory to the primary worktree of its repository,
# reporting the ones that cannot take part, and collapsing every worktree of a
# repository onto a single entry.
collect_migration_targets() {
  local candidate canon pointer primary known
  local seen=()

  for candidate in "$@"; do
    canon=$(canonical_dir "$candidate") || true
    if [ -z "$canon" ]; then
      migrate_error "$candidate: no such directory"
      continue
    fi
    if [ ! -e "$canon/.git" ]; then
      migrate_warn "$canon: not a git repository; skipped"
      continue
    fi
    if [ -L "$canon/.git" ]; then
      migrate_error "$canon: .git is a symlink; resolve it before migrating"
      continue
    fi
    if [ -f "$canon/.git" ]; then
      if ! pointer=$(read_gitdir_pointer "$canon/.git"); then
        migrate_error "$canon: unreadable .git file"
        continue
      fi
      if [ ! -e "$pointer" ]; then
        migrate_error "$canon: orphaned worktree; its repository '$pointer' no longer exists"
        continue
      fi
    fi
    local common_dir
    if common_dir=$(git -C "$canon" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
      case "$(canonical_dir "$common_dir")" in
        "$REPO_DIR_CANON"/*)
          migrate_warn "$canon: already managed by git operator; skipped"
          continue
          ;;
      esac
    fi
    if ! primary=$(resolve_primary_worktree "$canon"); then
      migrate_error "$canon: unable to resolve its repository"
      continue
    fi
    primary=$(canonical_dir "$primary") || true
    if [ -z "$primary" ]; then
      migrate_error "$canon: its repository no longer has a worktree"
      continue
    fi

    local duplicate=false
    for known in "${seen[@]}"; do
      if [ "$known" = "$primary" ]; then
        duplicate=true
        break
      fi
    done
    if [ "$duplicate" = true ]; then
      continue
    fi
    seen+=("$primary")
    MIGRATION_TARGETS+=("$primary")
  done
}

cmd_migrate() {
  local all=false
  local dry_run=false
  local assume_yes=false
  local explicit_project=""
  local positional_args=()

  MIGRATE_KEEP_BACKUP=false
  MIGRATE_FSCK=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --all)
        all=true
        shift
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      --yes)
        assume_yes=true
        shift
        ;;
      --keep-backup)
        MIGRATE_KEEP_BACKUP=true
        shift
        ;;
      --fsck)
        MIGRATE_FSCK=true
        shift
        ;;
      --project-name)
        if [ $# -lt 2 ] || [ -z "$2" ]; then
          echo "error: --project-name requires a value" >&2
          return 1
        fi
        explicit_project="$2"
        shift 2
        ;;
      --project-name=*)
        explicit_project="${1#--project-name=}"
        if [ -z "$explicit_project" ]; then
          echo "error: --project-name requires a value" >&2
          return 1
        fi
        shift
        ;;
      --)
        shift
        positional_args+=("$@")
        break
        ;;
      -*)
        echo "error: unknown option '$1'" >&2
        return 1
        ;;
      *)
        positional_args+=("$1")
        shift
        ;;
    esac
  done

  MIGRATE_ERRORS=()
  MIGRATE_WARNINGS=()
  MIGRATE_CLAIMED_PROJECTS=()
  MIGRATION_TARGETS=()

  WORKTREE_DIR_CANON=$(canonical_dir "$WORKTREE_DIR")
  REPO_DIR_CANON=$(canonical_dir "$REPO_DIR")

  local candidates=()
  if [ "$all" = true ]; then
    if [ ${#positional_args[@]} -gt 0 ]; then
      echo "error: --all does not take path arguments" >&2
      return 1
    fi
    if [ -n "$explicit_project" ]; then
      echo "error: --all and --project-name cannot be used together" >&2
      return 1
    fi
    if [ "$assume_yes" = false ]; then
      dry_run=true
    fi
    local entry
    for entry in "$WORKTREE_DIR_CANON"/*/; do
      entry="${entry%/}"
      [ -d "$entry" ] || continue
      candidates+=("$entry")
    done
    if [ ${#candidates[@]} -eq 0 ]; then
      echo "Nothing to migrate in '$WORKTREE_DIR'."
      return 0
    fi
    collect_migration_targets "${candidates[@]}"
  else
    if [ ${#positional_args[@]} -eq 0 ]; then
      echo "error: migrate requires <path> or --all" >&2
      echo "usage: git operator migrate [--dry-run] [--project-name <name>] [--keep-backup] [--fsck] <path>..." >&2
      echo "       git operator migrate --all [--yes] [--keep-backup] [--fsck]" >&2
      return 1
    fi
    if [ -n "$explicit_project" ] && [ ${#positional_args[@]} -ne 1 ]; then
      echo "error: --project-name applies to a single path" >&2
      return 1
    fi
    MIGRATION_TARGETS=("${positional_args[@]}")
  fi

  local migrated=0 skipped=0 target status
  for target in "${MIGRATION_TARGETS[@]}"; do
    set +e
    plan_migration "$target" "$explicit_project"
    status=$?
    set -e
    if [ $status -eq 2 ]; then
      skipped=$((skipped + 1))
      continue
    fi
    if [ $status -ne 0 ]; then
      continue
    fi

    if [ "$dry_run" = true ]; then
      print_migration_plan "$PLAN_PRIMARY" "$PLAN_PROJECT" "${PLAN_WORKTREES[@]}"
      migrated=$((migrated + 1))
      continue
    fi

    set +e
    migrate_execute "$PLAN_PRIMARY" "$PLAN_PROJECT" "${PLAN_WORKTREES[@]}"
    status=$?
    set -e
    if [ $status -eq 0 ]; then
      migrated=$((migrated + 1))
    fi
  done

  echo
  if [ "$dry_run" = true ]; then
    echo "Planned: $migrated repositories, skipped: $skipped, warnings: ${#MIGRATE_WARNINGS[@]}, errors: ${#MIGRATE_ERRORS[@]}"
    if [ "$all" = true ] && [ "$assume_yes" = false ]; then
      echo "Rerun with --yes to apply."
    fi
  else
    echo "Migrated: $migrated repositories, skipped: $skipped, warnings: ${#MIGRATE_WARNINGS[@]}, errors: ${#MIGRATE_ERRORS[@]}"
  fi

  if [ ${#MIGRATE_ERRORS[@]} -gt 0 ]; then
    echo
    echo "Errors:" >&2
    local message
    for message in "${MIGRATE_ERRORS[@]}"; do
      echo "  $message" >&2
    done
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
  git operator migrate [--dry-run] [--project-name <name>] [--keep-backup] [--fsck] <path>...
  git operator migrate --all [--yes] [--keep-backup] [--fsck]
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
    migrate)
      cmd_migrate "$@"
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
