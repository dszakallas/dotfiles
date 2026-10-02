ctx:
{ pkgs, ... }:
{
  bikeshed.emacs.doomUnstraightened = {
    enable = true;
    doomDir = ./doom.d;
    experimentalFetchTree = true;
    extraBinPackages = with pkgs; [
      ripgrep
      git
      fd
      vscode-langservers-extracted
    ];
  };

  home.packages = with pkgs; [
    vscode-langservers-extracted
  ];
}
