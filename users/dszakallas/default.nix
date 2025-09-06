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
      # Let's put the keys into to the SSH folder so we have a stable
      # identity for the macOS Keychain
      file.".ssh/sk0".source = "${self}/common/keys/sk0";
      file.".ssh/sk0.pub".source = "${self}/common/keys/sk0.pub";
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
          config = "${self}/common/spacemacs.d";
        };
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
      github = {
        enable = true;
        ssh = {
          enable = true;
          matchBlocks = {
            "git" = {
              identityFile = "~/.ssh/sk0";
              isFIDO2 = true;
            };
          };
        };
      };
    };
  };
}
