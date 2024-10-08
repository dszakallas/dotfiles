{ self, pkgs, config, system, lib, ... }:
with lib;
let
  unmanagedFile = f: ''
    # Unmanaged local overrides
    [[ -s "$HOME/.local/share/${f}" ]] && source "$HOME/.local/share/${f}"
  '';
  net = with pkgs; [ minio-client ];
  files = with pkgs; [
    age bat findutils fswatch gawk minio-client ripgrep rsync sops tree
  ];
  adm = with pkgs; [ htop ncdu ];
  nix = with pkgs; [ nixfmt-classic devenv ];
  dev = with pkgs; [ delta jq yq ];
in
{
  imports = [
    ./macos
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
    # k8s
    ({pkgs, config, ...}: {
      options = {
        davids.k8stools = {
          enable = mkEnableOption "Kubernetes tools";
        };
      };
      config = mkIf config.davids.k8stools.enable {
        home.packages = with pkgs; [ kubectl kubernetes-helm k9s fluxcd kustomize vcluster skopeo oras ];
        programs.zsh.shellAliases = {
          k = "kubectl";
        };
      };
    })
    # Emacs
    ({pkgs, config, ...}: {
      options = {
        davids.emacs = {
          enable = mkEnableOption "Emacs (wrappers)";
        };
      };
      config = mkIf config.davids.emacs.enable {
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
        home.file.".spacemacs.d".source = ./his.spacemacs.d;
        programs.zsh.shellAliases = {
          e = "ect";
        };
      };
    })
  ];
  config = {
    home = {
      packages = lists.flatten [ adm net files dev nix ];
      file.".gitconfig".text = builtins.readFile ./his.gitconfig;
      file.".global.gitignore".source = ./his.global.gitignore;
      file.".vimrc".source = ./his.vimrc;
      sessionVariables = {
        EDITOR = "vim";
        LANG = "en_US.UTF-8";
      };
    };
    programs = {
      vim = {
          enable = true;
          plugins = with pkgs.vimPlugins; [ vim-airline vim-fugitive vim-surround nerdcommenter ctrlp-vim syntastic srcery-vim editorconfig-vim tagbar ];
          settings = { ignorecase = true; };
          extraConfig = builtins.readFile ./his.vimrc;
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
          export PATH="$HOME/.local/bin:$PATH"
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
          export PATH="$HOME/.local/bin:$PATH"
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
        };
      };
    };
  };
}
