{self, pkgs, davids-dotfiles, ...}:
{
  users.users.davidszakallas = {
    name = "davidszakallas";
    home = "/Users/davidszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.davidszakallas = {
    imports = [
      davids-dotfiles.homeModules.default
    ];

    home = {
      username = "davidszakallas";
      homeDirectory = "/Users/davidszakallas";
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
  };
}
