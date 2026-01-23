{
  self,
  davids-dotfiles-common,
  davids-dotfiles-private,
  homeModules,
  packages,
  ...
}:
{
  pkgs,
  system,
  lib,
  ...
}:
{
  users.users.dszakallas = {
    name = "dszakallas";
    home = "/Users/dszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.dszakallas = rec {
    imports = [
      davids-dotfiles-common.homeModules.base
      davids-dotfiles-common.homeModules.emacs
      davids-dotfiles-common.homeModules.github
      davids-dotfiles-private.homeModules.default
      davids-dotfiles-private.homeModules.pure
      homeModules.id
      homeModules.gemini
    ];

    home = {
      username = "dszakallas";
      homeDirectory = "/Users/dszakallas";
      stateVersion = "24.05";
      # TODO move to common
      packages = [
        packages.${system}.npm."@augmentcode/auggie"
      ]
      ++ (with pkgs; [
        fluxcd-operator
      ]);
    };

    programs.home-manager.enable = true;

    davids = {
      # Impure brew programs
      brew = {
        enable = true;
        prefix = "/opt/homebrew";
      };

      k8stools.enable = true;
      emacs = {
        enable = true;
        daemon.enable = true;
        spacemacs = {
          enable = true;
          config = {
            enable = true;
            path = "${self}/common/spacemacs.d";
          };
        };
      };
      pure.enable = true;
      ssh = {
        enable = true;
        agent.enable = true;
      };
      git.enable = true;
      github = {
        enable = true;
        ssh = {
          enable = true;
        };
      };
    };
  };
}
