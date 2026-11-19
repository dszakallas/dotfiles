# bash completion for git-project / git project
# shellcheck shell=bash

__git_project_expand_path() {
  local raw_path="$1"
  case "$raw_path" in
    \~)
      printf '%s' "$HOME"
      ;;
    \~/*)
      printf '%s/%s' "$HOME" "${raw_path#\~/}"
      ;;
    *)
      printf '%s' "$raw_path"
      ;;
  esac
}

__git_project_git_config_path() {
  local val
  if val=$(git config --path --get "$1" 2>/dev/null) && [[ -n "$val" ]]; then
    printf '%s' "$val"
    return 0
  fi
  return 1
}

__git_project_repo_dir() {
  if [[ -n "${GIT_PROJECT_REPOS_ROOT:-}" ]]; then
    __git_project_expand_path "$GIT_PROJECT_REPOS_ROOT"
    return 0
  fi
  __git_project_git_config_path project.reposRoot && return 0
  __git_project_expand_path "$HOME/projects/repos"
}

__git_project_worktree_dir() {
  if [[ -n "${GIT_PROJECT_WORKTREES_ROOT:-}" ]]; then
    __git_project_expand_path "$GIT_PROJECT_WORKTREES_ROOT"
    return 0
  fi
  __git_project_git_config_path project.worktreesRoot && return 0
  __git_project_expand_path "$HOME/projects/worktrees"
}

__git_project_list_projects() {
  local repo_dir entry name
  repo_dir=$(__git_project_repo_dir)
  [[ -d "$repo_dir" ]] || return 0
  for entry in "$repo_dir"/*.git; do
    [[ -d "$entry" ]] || continue
    name="${entry##*/}"
    printf '%s\n' "${name%.git}"
  done
}

__git_project_list_worktrees() {
  local project="${1%.git}"
  [[ -n "$project" ]] || return 0

  local repo_dir wt_dir target_repo wt_dir_canon target_repo_canon line wt wt_canon
  repo_dir=$(__git_project_repo_dir)
  wt_dir=$(__git_project_worktree_dir)
  target_repo="$repo_dir/${project}.git"
  [[ -d "$target_repo" ]] || return 0

  wt_dir_canon=$(cd "$wt_dir" 2>/dev/null && pwd -P) || return 0
  target_repo_canon=$(cd "$target_repo" 2>/dev/null && pwd -P) || return 0

  while IFS= read -r line; do
    case "$line" in
      'worktree '*)
        wt="${line#worktree }"
        wt_canon=$(cd "$wt" 2>/dev/null && pwd -P) || continue
        [[ "$wt_canon" == "$target_repo_canon" ]] && continue
        if [[ "${wt_canon%/*}" == "$wt_dir_canon" ]]; then
          printf '%s\n' "${wt_canon##*/}"
        fi
        ;;
    esac
  done < <(git -C "$target_repo" worktree list --porcelain 2>/dev/null)
}

__git_project_list_refs() {
  local project="${1%.git}"
  [[ -n "$project" ]] || return 0
  local repo_dir target_repo
  repo_dir=$(__git_project_repo_dir)
  target_repo="$repo_dir/${project}.git"
  [[ -d "$target_repo" ]] || return 0
  git -C "$target_repo" for-each-ref --format='%(refname:short)' refs/heads refs/remotes refs/tags 2>/dev/null
}

__git_project_complete_words() {
  local cur="$1"
  shift
  local words_list="$*"
  COMPREPLY=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && COMPREPLY+=("$line")
  done < <(compgen -W "$words_list" -- "$cur")
}

_git_project() {
  local cmd_idx="${__git_cmd_idx:-0}"
  local -a comp_words
  local comp_cword

  if [[ -n "${__git_cmd_idx:-}" ]]; then
    # shellcheck disable=SC2154
    comp_words=("${words[@]}")
    # shellcheck disable=SC2154
    comp_cword="$cword"
  else
    comp_words=("${COMP_WORDS[@]}")
    comp_cword="$COMP_CWORD"
  fi

  local cur="${comp_words[comp_cword]:-}"
  local prev=""
  if (( comp_cword > 0 )); then
    prev="${comp_words[comp_cword-1]:-}"
  fi
  local rel=$((comp_cword - cmd_idx))

  if (( rel <= 1 )); then
    __git_project_complete_words "$cur" "clone init delete migrate worktree get-reponame help"
    return 0
  fi

  local subcmd="${comp_words[cmd_idx+1]:-}"
  local i arg pos_idx=0
  local -a pos_args=()
  for (( i = cmd_idx + 2; i < comp_cword; i++ )); do
    arg="${comp_words[i]}"
    case "$arg" in
      --worktree-name|--project-name)
        ((i++))
        ;;
      -*)
        ;;
      *)
        pos_args+=("$arg")
        ;;
    esac
  done
  pos_idx=${#pos_args[@]}

  case "$subcmd" in
    clone)
      if [[ "$prev" == "--worktree-name" ]]; then
        COMPREPLY=()
        return 0
      fi
      if [[ "$cur" == -* ]]; then
        __git_project_complete_words "$cur" "--no-worktree --worktree-name --no-beads"
        return 0
      fi
      COMPREPLY=()
      ;;
    init)
      if [[ "$prev" == "--worktree-name" ]]; then
        COMPREPLY=()
        return 0
      fi
      if [[ "$cur" == -* ]]; then
        __git_project_complete_words "$cur" "--all --no-worktree --worktree-name --no-beads"
        return 0
      fi
      if (( pos_idx == 0 )); then
        __git_project_complete_words "$cur" "$(__git_project_list_projects)"
      fi
      ;;
    delete)
      if [[ "$cur" == -* ]]; then
        __git_project_complete_words "$cur" "-f --force"
        return 0
      fi
      if (( pos_idx == 0 )); then
        __git_project_complete_words "$cur" "$(__git_project_list_projects)"
      fi
      ;;
    migrate)
      if [[ "$prev" == "--project-name" ]]; then
        COMPREPLY=()
        return 0
      fi
      if [[ "$cur" == -* ]]; then
        __git_project_complete_words "$cur" "--all --dry-run --yes --keep-backup --fsck --project-name"
        return 0
      fi
      COMPREPLY=()
      while IFS= read -r line; do
        COMPREPLY+=("$line")
      done < <(compgen -d -- "$cur")
      ;;
    worktree)
      local wt_subcmd="${comp_words[cmd_idx+2]:-}"
      if (( rel == 2 )); then
        __git_project_complete_words "$cur" "add remove rm list ls"
        return 0
      fi
      local -a wt_pos=()
      for (( i = cmd_idx + 3; i < comp_cword; i++ )); do
        arg="${comp_words[i]}"
        case "$arg" in
          -*)
            ;;
          *)
            wt_pos+=("$arg")
            ;;
        esac
      done
      local wt_pos_idx=${#wt_pos[@]}
      case "$wt_subcmd" in
        add)
          if [[ "$cur" == -* ]]; then
            __git_project_complete_words "$cur" "--fetch"
            return 0
          fi
          if (( wt_pos_idx == 0 )); then
            __git_project_complete_words "$cur" "$(__git_project_list_projects)"
          elif (( wt_pos_idx == 2 )); then
            __git_project_complete_words "$cur" "$(__git_project_list_refs "${wt_pos[0]}")"
          fi
          ;;
        remove|rm)
          if [[ "$cur" == -* ]]; then
            __git_project_complete_words "$cur" "-f --force"
            return 0
          fi
          if (( wt_pos_idx == 0 )); then
            __git_project_complete_words "$cur" "$(__git_project_list_projects)"
          elif (( wt_pos_idx == 1 )); then
            __git_project_complete_words "$cur" "$(__git_project_list_worktrees "${wt_pos[0]}")"
          fi
          ;;
        list|ls)
          if (( wt_pos_idx == 0 )); then
            __git_project_complete_words "$cur" "$(__git_project_list_projects)"
          fi
          ;;
      esac
      ;;
    get-reponame|help)
      COMPREPLY=()
      ;;
  esac
}

if [[ $(type -t compopt) = "builtin" ]]; then
  complete -o default -F _git_project git-project
else
  complete -o default -o nospace -F _git_project git-project
fi
