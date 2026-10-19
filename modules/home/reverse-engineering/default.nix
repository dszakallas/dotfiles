{ packages, ... }@ctx:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.modules.reverse-engineering;
in
{
  options.modules.reverse-engineering = {
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
      rea = "${packages.${system}.rea}/share/skills/rea";
    };
  };
}
