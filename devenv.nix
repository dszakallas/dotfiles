{ pkgs, davids-dotfiles-common, ... }@args:
let
  lib' = davids-dotfiles-common.lib;
in
{
  imports = [
    davids-dotfiles-common.devenvModules.recommended
  ];

  profiles = lib'.importRec1 ./devenv args;

  git-hooks.hooks.nixfmt = {
    excludes = [ "pkgs/npm/_.*\\.nix" ];
  };

  git-hooks.hooks.markdownlint = {
    excludes = [
      "users/shared/skills/.*"
      "users/shared/instructions/.*"
      "pkgs/agentskills/local/skills/.*"
    ];
    settings.configuration = {
      # instructions in certain folders will be merged into a single file
      MD041 = false;
    };
  };
}
