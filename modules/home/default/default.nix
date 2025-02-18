{ self, davids-dotfiles, ... }@ctx:
{
  pkgs,
  config,
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
    # TODO error building backblaze-b2
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
  ];
  dev = with pkgs; [
    delta
    git-lfs
    nodejs_23 # Needed for certain emacs packages such as lsp
    jq
    yq-go
    asciinema
  ];
  av = with pkgs; [ ffmpeg ];
  moduleName = "davids-dotfiles/default";
in
{
  imports = [
    (import ./fzf.nix ctx)
    (import ./github.nix ctx)
    (import ./k8s.nix ctx)
    (import ./emacs.nix ctx)
  ] ++ (lib.optionals hostPlatform.isDarwin [ (import ./darwin ctx) ]);
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
      shellAliases = {
        la = "ls -la";
        g = "git";
        v = "vim";
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
            export PATH="$HOME/.davids/bin:$PATH"
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
            export PATH="$HOME/.davids/bin:$PATH"
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
      };
    };
  };
}
