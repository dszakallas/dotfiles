{ self, pkgs, davids-dotfiles, davids-dotfiles-private, poetry2nix, system, ...
}: {
  users.users.dszakallas = {
    name = "dszakallas";
    home = "/Users/dszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.dszakallas = {
    imports = [
      davids-dotfiles.homeModules.default
      davids-dotfiles-private.homeModules.default
      davids-dotfiles-private.homeModules.pure
    ];

    home = {
      username = "dszakallas";
      homeDirectory = "/Users/dszakallas";
      stateVersion = "24.05";
    };

    programs.home-manager.enable = true;

    # Impure brew programs
    davids.brew = {
      enable = true;
      prefix = "/opt/homebrew";
    };

    davids.k8stools.enable = true;
    davids.emacs.enable = true;
    davids.pure.enable = true;
    davids.ssh.enable = true;
  };
}
