{
  self,
  davids-dotfiles-private,
  homeModules,
  ...
}:
{ pkgs, system, ... }:
{
  users.users.dszakallas = {
    name = "dszakallas";
    home = "/Users/dszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.dszakallas = {
    imports = [
      homeModules.default
      davids-dotfiles-private.homeModules.default
      davids-dotfiles-private.homeModules.pure
    ];

    home = {
      username = "dszakallas";
      homeDirectory = "/Users/dszakallas";
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
    davids.pure.enable = true;
    davids.ssh.enable = true;
  };
}
