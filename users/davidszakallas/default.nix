{
  self,
  davids-dotfiles-common,
  davids-dotfiles-private,
  packages,
  ...
}:
{
  pkgs,
  lib,
  system,
  ...
}:
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
      davids-dotfiles-private.homeModules.kolobok
    ];

    home = {
      username = "davidszakallas";
      homeDirectory = "/Users/davidszakallas";
      stateVersion = "24.05";
      packages = [
        packages.${system}.npm."@openai/codex"
      ]
      ++ (with pkgs; [
        ffmpeg
        asciinema
        awscli2
        minio-client
        backblaze-b2
        rclone
        yt-dlp
        gemini-cli-bin
        google-cloud-sdk
      ]);
      # Let's put the keys into to the SSH folder so we have a stable
      # identity for the macOS Keychain
      file.".ssh/sk1".source = "${self}/common/keys/sk1";
      file.".ssh/sk1.pub".source = "${self}/common/keys/sk1.pub";
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
        spacemacs = {
          enable = true;
          config = "${self}/common/spacemacs.d";
        };
      };
      jupiter.enable = true;
      kolobok.enable = true;
      ssh = {
        enable = true;
        agent.enable = true;
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
      github = {
        enable = true;
        ssh = {
          enable = true;
          matchBlocks = {
            "git" = {
              identityFile = "~/.ssh/sk1";
              isFIDO2 = true;
            };
          };
        };
      };
    };
  };
}
