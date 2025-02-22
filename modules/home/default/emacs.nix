{ packages, ... }:
{
  pkgs,
  config,
  lib,
  system,
  ...
}:
with lib;
{
  options = {
    davids.emacs = {
      enable = mkEnableOption "Emacs configuration";
      spacemacs = mkOption {
        default = { };
        type = types.submodule {
          options = {
            enable = mkEnableOption "Enable Spacemacs management";
          };
        };
      };
    };
  };
  config = mkIf config.davids.emacs.enable (
    let
      spacemacs = packages.${system}.spacemacs;
      loadSpacemacsInit = f: ''
        (setq spacemacs-start-directory "${spacemacs.out}/share/spacemacs/")
        (add-to-list 'load-path spacemacs-start-directory)
        (load "${f}" nil t)
      '';
    in
    {
      home.packages = [
        pkgs.nodejs_23 # Needed for certain emacs packages such as lsp
        spacemacs
      ];
      home.file.".davids/bin/ect" = {
        text = ''
          #!/bin/sh
          exec emacsclient --tty "$@"
        '';
        executable = true;
      };
      home.file.".davids/bin/ecw" = {
        text = ''
          #!/bin/sh
          exec emacsclient --reuse-frame -a "" "$@"
        '';
        executable = true;
      };
      home.file.".davids/bin/ec" = {
        text = ''
          #!/bin/sh
          exec emacsclient "$@"
        '';
        executable = true;
      };
      programs.zsh.shellAliases = {
        e = "ect";
      };
      home.file.".spacemacs.d" = mkIf config.davids.emacs.spacemacs.enable {
        source = ./his.spacemacs.d;
      };
      home.file.".emacs.d/init.el" = mkIf config.davids.emacs.spacemacs.enable {
        text = loadSpacemacsInit "init";
      };
      home.file.".emacs.d/early-init.el" = mkIf config.davids.emacs.spacemacs.enable {
        text = loadSpacemacsInit "early-init";
      };
      home.file.".emacs.d/dump-init.el" = mkIf config.davids.emacs.spacemacs.enable {
        text = loadSpacemacsInit "dump-init";
      };
    }
  );
}
