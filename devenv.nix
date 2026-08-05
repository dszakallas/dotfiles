{ pkgs, bikeshed, ... }@args:
let
  lib' = bikeshed.lib;
in
{
  imports = [
    bikeshed.devenvModules.recommended
  ];

  profiles = lib'.importRec1 ./devenv args;

  git-hooks.hooks.nixfmt = {
    excludes = [ "pkgs/npm/_.*\\.nix" ];
  };

  git-hooks.hooks.markdownlint = {
    excludes = [
      "hosts/shared/skills/.*"
      "hosts/shared/instructions/.*"
      "pkgs/agentskills/local/skills/.*"
    ];
    settings.configuration = {
      # instructions in certain folders will be merged into a single file
      MD041 = false;
    };
  };
}
