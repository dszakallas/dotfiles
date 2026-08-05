{ bikeshed, ... }:
let
  primaryUser = "dszakallas";
in
{
  imports = [
    bikeshed.homeModules.base
    bikeshed.homeModules.ssh
    bikeshed.homeModules.agents
  ];

  home = {
    username = primaryUser;
    homeDirectory = "/home/${primaryUser}";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
