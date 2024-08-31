{self, pkgs, ...}:
{
  users.users.davidszakallas = {
    name = "davidszakallas";
    home = "/Users/davidszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.davidszakallas = {
    imports = [
      "${self}/modules/home/davids-dotfiles"
    ];

    home = {
      username = "davidszakallas";
      homeDirectory = "/Users/davidszakallas";
      stateVersion = "24.05";
    };

    programs.home-manager.enable = true;

    # Impure programs
    programs.brew = {
      enable = true;
      prefix = "/opt/homebrew";
    };
  };
}