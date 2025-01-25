{ self, davids-dotfiles, ... }:
{
  pkgs,
  config,
  system,
  lib,
  hostPlatform,
  ...
}:
with lib;
let
  unmanagedFile = f: ''
    # Unmanaged local overrides
    [[ -s "$HOME/.local/share/${f}" ]] && source "$HOME/.local/share/${f}"
  '';
  cloud = with pkgs; [
    awscli2
    minio-client
    backblaze-b2
  ];
  files = with pkgs; [
    age
    bat
    findutils
    fswatch
    gawk
    ripgrep
    rsync
    sops
    tree
  ];
  adm = with pkgs; [
    htop
    ncdu
    nmap
    tmux
  ];
  nix = with pkgs; [
    devenv
    nixfmt-classic
  ];
  dev = with pkgs; [
    delta
    git-lfs
    jq
    pipx
    yq-go
    asciinema
  ];
  av = with pkgs; [ ffmpeg ];
  moduleName = "davids-dotfiles/default";
in
{
  imports = [
    # fzf
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ fzf ];
        programs.bash.bashrcExtra = ''
          eval "$(fzf --bash)";
        '';
        programs.zsh.oh-my-zsh.plugins = [ "fzf" ];
        programs.vim.plugins = with pkgs.vimPlugins; [ fzf-vim ];
      }
    )
    # GitHub CLI
    (
      { pkgs, ... }:
      {
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
      }
    )
    # k8s
    (
      { pkgs, config, ... }:
      {
        options = {
          davids.k8stools = {
            enable = mkEnableOption "Kubernetes tools";
          };
        };
        config = mkIf config.davids.k8stools.enable {
          home.packages = with pkgs; [
            kubectl
            kubernetes-helm
            k9s
            fluxcd
            kustomize
            vcluster
            skopeo
            oras
          ];
          programs.zsh.shellAliases = {
            k = "kubectl";
          };
        };
      }
    )
    # Emacs
    (
      { pkgs, config, ... }:
      {
        options = {
          davids.emacs = {
            enable = mkEnableOption "Emacs configuration";
            spacemacs = mkOption {
              default = { };
              type = types.submodule {
                options = {
                  enable = mkEnableOption "Enable Spacemacs management";
                };
              };
            };
          };
        };
        config = mkIf config.davids.emacs.enable (
          let
            spacemacs = davids-dotfiles.packages.spacemacs.${system};
            loadSpacemacsInit = f: ''
              (setq spacemacs-start-directory "${spacemacs.out}/share/spacemacs/")
              (load-file (concat spacemacs-start-directory "${f}"))
            '';
          in
          {
            home.packages = [ spacemacs ];
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
            programs.zsh.shellAliases = {
              e = "ect";
            };
            home.file.".spacemacs.d" = mkIf config.davids.emacs.spacemacs.enable {
              source = ./his.spacemacs.d;
            };
            home.file.".emacs.d/init.el" = mkIf config.davids.emacs.spacemacs.enable {
              text = loadSpacemacsInit "init.el";
            };
            home.file.".emacs.d/early-init.el" = mkIf config.davids.emacs.spacemacs.enable {
              text = loadSpacemacsInit "early-init.el";
            };
            home.file.".emacs.d/dump-init.el" = mkIf config.davids.emacs.spacemacs.enable {
              text = loadSpacemacsInit "dump-init.el";
            };
          }
        );
      }
    )
  ] ++ (lib.optionals hostPlatform.isDarwin [ ./darwin ]);
  options = {
    davids.ssh.enable = mkEnableOption "SSH goodies";
    davids.ssh.knownHostsLines =
      with types;
      mkOption {
        description = "Managed known_host file lines";
        type = lines;
        default = "";
      };
  };
  config = {
    home = {
      packages = lists.flatten [
        adm
        av
        files
        cloud
        dev
        nix
      ];
      file.".gitconfig".text = davids-dotfiles.lib.textRegion {
        name = moduleName;
        content = builtins.readFile ./his.gitconfig;
      };
      file.".global.gitignore".text = davids-dotfiles.lib.textRegion {
        name = moduleName;
        content = builtins.readFile ./his.global.gitignore;
      };
      file.".vimrc".text = davids-dotfiles.lib.textRegion {
        name = moduleName;
        comment-char = ''"'';
        content = builtins.readFile ./his.vimrc;
      };
      sessionVariables = {
        EDITOR = "vim";
        LANG = "en_US.UTF-8";
      };
      file.".ssh/davids.known_hosts".text = mkIf config.davids.ssh.enable (
        davids-dotfiles.lib.textRegion {
          name = moduleName;
          content = config.davids.ssh.knownHostsLines;
        }
      );
    };
    programs = {
      vim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          vim-airline
          vim-fugitive
          vim-surround
          nerdcommenter
          ctrlp-vim
          syntastic
          srcery-vim
          editorconfig-vim
          tagbar
        ];
        settings = {
          ignorecase = true;
        };
        extraConfig = builtins.readFile ./his.vimrc;
      };

      direnv = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };

      ssh = mkIf config.davids.ssh.enable {
        enable = true;
        # Unmanaged local overrides
        includes = [ "~/.local/share/ssh/config" ];

        # default ~/.ssh/known_hosts is unmanaged. ~/.ssh/davids.known_hosts is managed by this module
        userKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/davids.known_hosts";
      };

      bash = {
        enable = true;
        bashrcExtra = unmanagedFile "bashrc";
        profileExtra =
          ''
            export PATH="$HOME/.files/bin:$PATH"
            # Unmanaged executables
            export PATH="$HOME/.local/bin:$PATH"
          ''
          + unmanagedFile "env";
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
        envExtra =
          ''
            export PATH="$HOME/.files/bin:$PATH"
            # Unmanaged executables
            export PATH="$HOME/.local/bin:$PATH"
          ''
          + unmanagedFile "env";

        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
            "direnv"
          ];
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
