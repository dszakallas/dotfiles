{self, pkgs, ...}:
{
  users.users.dszakallas = {
    name = "dszakallas";
    home = "/Users/dszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.dszakallas = {
    imports = [
      "${self}/modules/home/davids-dotfiles"
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
  };
}
