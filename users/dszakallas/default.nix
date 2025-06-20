{
  self,
  davids-dotfiles-common,
  davids-dotfiles-private,
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
      davids-dotfiles-common.homeModules.default
      davids-dotfiles-private.homeModules.default
      davids-dotfiles-private.homeModules.pure
    ];

    home = rec {
      username = "dszakallas";
      homeDirectory = "/Users/dszakallas";
      stateVersion = "24.05";

      file.".gitconfig".text = davids-dotfiles-common.lib.textRegion {
        name = "dotfiles/users/${username}";
        content = ''
          [user]
            name = Dávid Szakállas
            email = 5807322+dszakallas@users.noreply.github.com
          [github]
            user = dszakallas
        '';
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
