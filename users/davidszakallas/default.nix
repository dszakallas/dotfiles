{
  self,
  davids-dotfiles-common,
  davids-dotfiles-private,
  ...
}:
{ pkgs, ... }:
{
  users.users.davidszakallas = {
    name = "davidszakallas";
    home = "/Users/davidszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.davidszakallas = rec {
    imports = [
      davids-dotfiles-common.homeModules.default
      davids-dotfiles-private.homeModules.default
      davids-dotfiles-private.homeModules.jupiter
    ];

    home = rec {
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
    davids.jupiter.enable = true;
    davids.ssh.enable = true;
    davids.gpg = {
      enable = true;
      defaultKey = "DAF51FB1E2246B94265E90B6D3743DE2308ADE59";
    };
  };
}
