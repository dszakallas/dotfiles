{ packages, ... }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.modules.notebooklm;
in
{
  options.modules.notebooklm = {
    enable = lib.mkEnableOption "NotebookLM CLI and agent skill" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      packages.${system}.notebooklm-py
    ];

    bikeshed.agents.skills.entries = {
      # The notebooklm-py package ships the skill next to the CLI it documents.
      notebooklm = "${packages.${system}.notebooklm-py}/share/skills/notebooklm-py/notebooklm";
    };
  };
}
