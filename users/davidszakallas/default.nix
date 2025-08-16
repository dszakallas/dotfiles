{
  self,
  davids-dotfiles-common,
  davids-dotfiles-private,
  ...
}:
{ pkgs, lib, ... }:
{
  users.users.davidszakallas = {
    name = "davidszakallas";
    home = "/Users/davidszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.davidszakallas = rec {
    imports = [
      davids-dotfiles-common.homeModules.base
      davids-dotfiles-common.homeModules.emacs
      davids-dotfiles-common.homeModules.github
      davids-dotfiles-private.homeModules.default
      davids-dotfiles-private.homeModules.jupiter
    ];

    home = {
      username = "davidszakallas";
      homeDirectory = "/Users/davidszakallas";
      stateVersion = "24.05";
      packages = with pkgs; [
        ffmpeg
        asciinema
        awscli2
        minio-client
        backblaze-b2
        yt-dlp
      ];
    };

    programs.home-manager.enable = true;

    davids = {
      # Impure brew programs
      brew = {
        enable = true;
        prefix = "/opt/homebrew";
      };
      k8stools = {
        enable = true;
      };
      emacs = {
        enable = true;
        daemon.enable = true;
        spacemacs.enable = true;
      };
      jupiter.enable = true;
      ssh.enable = true;
      gpg = {
        enable = true;
        defaultKey = "DAF51FB1E2246B94265E90B6D3743DE2308ADE59";
      };
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
