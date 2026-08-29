{ packages, ... }@ctx:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  git-operator-pkg = packages.${system}.git-operator;
in
{
  home.packages = [ git-operator-pkg ];

  home.file.".bikeshed/bin/git-operator-init-worktree-hook" = {
    executable = true;
    source = ./git-operator-init-worktree-hook.sh;
  };
}
