{ packages, ... }@ctx:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  git-project-pkg = packages.${system}.git-project;
  cfg = config.dotfiles.git.project;
in
{
  options.dotfiles.git.project = {
    enable = lib.mkEnableOption "git-project bare repository, worktree, and Beads management" // {
      default = true;
    };
    reposRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/projects/repos";
      description = "Directory where bare repositories are stored.";
    };
    worktreesRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/projects/worktrees";
      description = "Directory where linked worktrees are created.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ git-project-pkg ];

    home.file.".bikeshed/bin/git-project-init-worktree-hook" = {
      executable = true;
      source = ./git-project-init-worktree-hook.sh;
    };

    home.file.".bikeshed/share/git/template/hooks/post-checkout" = {
      executable = true;
      source = ./post-checkout.sh;
    };

    bikeshed.git.includes = [
      {
        path = pkgs.writeText "git-project-config" ''
          [init]
          	templateDir = ~/.bikeshed/share/git/template
          [project]
          	reposRoot = ${cfg.reposRoot}
          	worktreesRoot = ${cfg.worktreesRoot}
        '';
      }
    ];
  };
}
