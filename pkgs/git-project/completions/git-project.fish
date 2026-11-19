# fish completion for git-project / git project

function __git_project_repo_dir
    if set -q GIT_PROJECT_REPOS_ROOT; and test -n "$GIT_PROJECT_REPOS_ROOT"
        string replace -r '^~(?=/|$)' "$HOME" -- "$GIT_PROJECT_REPOS_ROOT"
        return 0
    end
    set -l val (git config --path --get project.reposRoot 2>/dev/null)
    if test $status -eq 0 -a -n "$val"
        printf '%s\n' "$val"
        return 0
    end
    printf '%s/projects/repos\n' "$HOME"
end

function __git_project_worktree_dir
    if set -q GIT_PROJECT_WORKTREES_ROOT; and test -n "$GIT_PROJECT_WORKTREES_ROOT"
        string replace -r '^~(?=/|$)' "$HOME" -- "$GIT_PROJECT_WORKTREES_ROOT"
        return 0
    end
    set -l val (git config --path --get project.worktreesRoot 2>/dev/null)
    if test $status -eq 0 -a -n "$val"
        printf '%s\n' "$val"
        return 0
    end
    printf '%s/projects/worktrees\n' "$HOME"
end

function __git_project_list_projects
    set -l repo_dir (__git_project_repo_dir)
    test -d "$repo_dir"; or return 0
    for entry in "$repo_dir"/*.git
        test -d "$entry"; or continue
        string replace -r '\.git$' '' -- (basename "$entry")
    end
end

function __git_project_cmd_tokens
    set -l tokens (commandline -opc)
    set -l cmd (basename -- "$tokens[1]")
    if test "$cmd" = git
        set -l idx (contains -i -- project $tokens)
        or return 1
        set tokens $tokens[$idx..-1]
    end
    for t in $tokens
        printf '%s\n' "$t"
    end
end

function __git_project_needs_subcmd
    set -l tokens (__git_project_cmd_tokens); or return 1
    test (count $tokens) -eq 1
end

function __git_project_using_subcmd
    set -l tokens (__git_project_cmd_tokens); or return 1
    test (count $tokens) -ge 2; and contains -- "$tokens[2]" $argv
end

function __git_project_worktree_subcmd
    set -l tokens (__git_project_cmd_tokens); or return 1
    test (count $tokens) -ge 2 -a "$tokens[2]" = worktree; or return 1
    if test (count $argv) -eq 0
        test (count $tokens) -eq 2
        return $status
    end
    test (count $tokens) -ge 3; and contains -- "$tokens[3]" $argv
end

# Register `git project` subcommand with fish's git completion
complete -c git -f -n 'functions -q __fish_git_needs_command; and __fish_git_needs_command' -a project -d 'Automate bare repositories, isolated agent worktrees, and Beads'

for cmd in git-project
    complete -c $cmd -e
end

# Shared rules for both `git-project` and `git project`
function __git_project_register_rules --argument-names cmd cond_prefix
    complete -c $cmd -f -n "$cond_prefix __git_project_needs_subcmd" -a clone -d 'Clone remote repo into bare repo, worktree, and Beads'
    complete -c $cmd -f -n "$cond_prefix __git_project_needs_subcmd" -a init -d 'Initialize new bare repo, worktree, and Beads'
    complete -c $cmd -f -n "$cond_prefix __git_project_needs_subcmd" -a delete -d 'Delete a managed bare repository'
    complete -c $cmd -f -n "$cond_prefix __git_project_needs_subcmd" -a migrate -d 'Migrate existing checkouts into managed layout'
    complete -c $cmd -f -n "$cond_prefix __git_project_needs_subcmd" -a worktree -d 'Manage worktrees for a project'
    complete -c $cmd -f -n "$cond_prefix __git_project_needs_subcmd" -a get-reponame -d 'Print managed project name for current worktree'
    complete -c $cmd -f -n "$cond_prefix __git_project_needs_subcmd" -a help -d 'Show usage summary'

    complete -c $cmd -f -n "$cond_prefix __git_project_using_subcmd clone init" -l no-worktree -d 'Create bare repository without initial worktree'
    complete -c $cmd -f -n "$cond_prefix __git_project_using_subcmd clone init" -l worktree-name -r -d 'Name for initial worktree'
    complete -c $cmd -f -n "$cond_prefix __git_project_using_subcmd clone init" -l no-beads -d 'Skip initializing shared Beads workspace'
    complete -c $cmd -f -n "$cond_prefix __git_project_using_subcmd init" -l all -d 'Reinitialize all existing managed projects'
    complete -c $cmd -f -n "$cond_prefix __git_project_using_subcmd init" -a '(__git_project_list_projects)'

    complete -c $cmd -f -n "$cond_prefix __git_project_using_subcmd delete" -s f -l force -d 'Remove active worktrees before deleting'
    complete -c $cmd -f -n "$cond_prefix __git_project_using_subcmd delete" -a '(__git_project_list_projects)'

    complete -c $cmd -n "$cond_prefix __git_project_using_subcmd migrate" -l all -d 'Migrate all repositories in worktree directory'
    complete -c $cmd -n "$cond_prefix __git_project_using_subcmd migrate" -l dry-run -d 'Show migration plan without applying'
    complete -c $cmd -n "$cond_prefix __git_project_using_subcmd migrate" -l yes -d 'Apply --all migration plan'
    complete -c $cmd -n "$cond_prefix __git_project_using_subcmd migrate" -l keep-backup -d 'Keep backup of original .git directory'
    complete -c $cmd -n "$cond_prefix __git_project_using_subcmd migrate" -l fsck -d 'Verify object connectivity after migration'
    complete -c $cmd -n "$cond_prefix __git_project_using_subcmd migrate" -l project-name -r -d 'Explicit project name for single path'

    complete -c $cmd -f -n "$cond_prefix __git_project_worktree_subcmd" -a 'add remove rm list ls'
    complete -c $cmd -f -n "$cond_prefix __git_project_worktree_subcmd add" -l fetch -d 'Fetch origin before creating worktree'
    complete -c $cmd -f -n "$cond_prefix __git_project_worktree_subcmd remove rm" -s f -l force -d 'Force removal of dirty worktree'
    complete -c $cmd -f -n "$cond_prefix __git_project_worktree_subcmd add remove rm list ls" -a '(__git_project_list_projects)'
end

__git_project_register_rules git-project ''
__git_project_register_rules git 'functions -q __fish_git_using_command; and __fish_git_using_command project;'
functions -e __git_project_register_rules
