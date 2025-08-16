{
  self,
  davids-dotfiles-common,
  davids-dotfiles-private,
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
    ];

    home = {
      username = "dszakallas";
      homeDirectory = "/Users/dszakallas";
      stateVersion = "24.05";
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
        spacemacs.enable = true;
      };
      pure.enable = true;
      ssh.enable = true;
      git = {
        enable = true;
        configLines = lib.mkBefore (
          davids-dotfiles-common.lib.textRegion {
            name = "dotfiles/users/${home.username}";
            content = ''
              [user]
                name = Dávid Szakállas
                email = 5807322+dszakallas@users.noreply.github.com
              [github]
                user = dszakallas
            '';
          }
        );
      };
      github.enable = true;
    };
  };
}
