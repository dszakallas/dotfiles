{ self, pkgs, config, system, ... }:
let 
  unmanagedFile = f : ''
    # Unmanaged local overrides
    [[ -s "$HOME/.local/share/${f}" ]] && source "$HOME/.local/share/${f}"
  '';
in
{
  imports = [
    ../macos
    # fzf
    ({pkgs, ...}: {
      home.packages = with pkgs; [ fzf ];
      programs.bash.bashrcExtra = ''
        eval "$(fzf --bash)";
      '';
      programs.zsh.oh-my-zsh.plugins = [ "fzf" ];
      programs.vim.plugins = with pkgs.vimPlugins; [ fzf-vim ];
    })
    # GitHub CLI
    ({pkgs, ...}: {
      home.packages = with pkgs; [ gh ];
      home.file.".files/share/gh.zsh".source = ./gh.zsh;
      programs.zsh = {
        initExtra = ''
          source "$HOME/.files/share/gh.zsh";
        '';
        oh-my-zsh.plugins = [ "gh" ];
      };
      home.sessionVariables = {
        GH_PAGER = "cat";
      };
    })
    # Emacs
    ({pkgs, ...}: {
      # Only adding wrappers for now
      home.file.".files/bin/ect" = {
        text = ''
          #!/bin/sh
          exec emacsclient --tty "$@"
        '';
        executable = true;
      };
      home.file.".files/bin/ecw" = {
        text = ''
          #!/bin/sh
          exec emacsclient --reuse-frame -a "" "$@"
        '';
        executable = true;
      };
      home.file.".files/bin/ec" = {
        text = ''
          #!/bin/sh
          exec emacsclient "$@"
        '';
        executable = true;
      };
    })
  ];
  home = {
    packages = (with pkgs; [ delta devenv ncdu jq yq bat ripgrep ]);
    file.".gitconfig".source = ./my.gitconfig;
    file.".global.gitignore".source = ./my.global.gitignore;
    file.".vimrc".source = ./my.vimrc;
    sessionVariables = {
      EDITOR = "vim";
    };
  };
  programs = {
    vim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [ vim-airline vim-fugitive vim-surround nerdcommenter ctrlp-vim syntastic srcery-vim editorconfig-vim tagbar ];
        settings = { ignorecase = true; };
        extraConfig = builtins.readFile ./my.vimrc;
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    bash = {
      enable = true;
      bashrcExtra = unmanagedFile "bashrc";
      profileExtra = ''
        export PATH="$HOME/.files/bin:$PATH" 
      '' + unmanagedFile "env";
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
        path = "$HOME/.histfile";
      };
      
      initExtra = unmanagedFile "zshrc";
      envExtra = ''
        export PATH="$HOME/.files/bin:$PATH" 
      '' + unmanagedFile "env";

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "direnv" ];
        theme = "clean";
      };

      shellAliases = {
        la = "ls -la";
        g = "git";
        v = "vim";
        e = "ect";
      };
    };
  };
}