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
      nil
      rust-analyzer
      gopls
      pyright
      typescript-language-server
      dart
      yaml-language-server
      taplo
      terraform-ls
      bash-language-server
      marksman
      buf
      vim-language-server
    ];
  };

  home.packages = with pkgs; [
    vscode-langservers-extracted
    fd
  ];
}
