#!/usr/bin/env bash
set -euo pipefail

repo_name="${REPO_NAME:-${1:-}}"
if [ -z "$repo_name" ]; then
  echo "error: REPO_NAME must be set (or passed as argument 1)" >&2
  exit 1
fi

repo_name="${repo_name%.git}"
template_dir="$HOME/.local/share/worktrees/$repo_name"

if [ -d "$template_dir" ]; then
  echo "Copying template files from '$template_dir' to worktree..."
  cp -R "$template_dir/." .
fi
