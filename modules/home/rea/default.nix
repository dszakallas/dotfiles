{ packages, ... }@ctx:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.dotfiles.rea;
in
{
  options.dotfiles.rea = {
    enable = lib.mkEnableOption "Reverse engineering tools and agent skills" // {
      default = true;
    };
    ghidraPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ghidra-bin;
      description = "The Ghidra package providing the decompiler.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      packages.${system}.rea
      cfg.ghidraPackage
    ];

    home.sessionVariables = {
      GHIDRA_INSTALL_DIR = "${cfg.ghidraPackage}/lib/ghidra";
    };

    bikeshed.agents.skills.entries = {
      # The rea package ships the skill next to the CLI it documents.
      reverse-engineer-anything = "${packages.${system}.rea}/share/skills/rea/reverse-engineer-anything";
    };
  };
}
