{
  self,
  davids-dotfiles-private,
  homeModules,
  ...
}:
{ pkgs, ... }:
{
  users.users.davidszakallas = {
    name = "davidszakallas";
    home = "/Users/davidszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.davidszakallas = {
    imports = [
      homeModules.default
      davids-dotfiles-private.homeModules.default
      davids-dotfiles-private.homeModules.jupiter
    ];

    home = {
      username = "davidszakallas";
      homeDirectory = "/Users/davidszakallas";
      stateVersion = "24.05";
      shellAliases = {
        docker = "podman";
      };
    };

    programs.home-manager.enable = true;

    # Impure brew programs
    davids.brew = {
      enable = true;
      prefix = "/opt/homebrew";
    };

    davids.k8stools.enable = true;
    davids.emacs = {
      enable = true;
      spacemacs.enable = true;
    };
    davids.jupiter.enable = true;
    davids.ssh.enable = true;
  };
}
