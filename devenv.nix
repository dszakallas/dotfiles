{ pkgs, davids-dotfiles-common, ... }@args:
{
  imports = [
    davids-dotfiles-common.devenvModules.recommended
  ];

  profiles = {
    agents.module = import ./devenv/profiles/agents args;
  };

  git-hooks.hooks.nixfmt = {
    excludes = [ "pkgs/npm/_.*\\.nix" ];
  };

  git-hooks.hooks.markdownlint = {
    excludes = [
      "users/skills/.*"
    ];
    settings.configuration = {
      # instructions in certain folders will be merged into a single file
      MD041 = false;
    };
  };
}
