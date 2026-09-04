#!/usr/bin/env bash

PATH="$HOME/.bikeshed/bin:$PATH"

PREV_HEAD="$1"
# shellcheck disable=SC2034
NEW_HEAD="$2"
IS_BRANCH="$3"
ZERO_OID="0000000000000000000000000000000000000000"

if [ "$PREV_HEAD" = "$ZERO_OID" ] && [ "$IS_BRANCH" -eq 1 ]; then
  echo "Running global post-worktree setup in: $(pwd)"
  REPO_NAME="$(git operator get-reponame)"
  export REPO_NAME
  git-operator-init-worktree-hook
fi
