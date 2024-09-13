{ pkgs, config, system, ... }:
with pkgs; with lib;
let 
  brew = config.davids.brew;
in
{
  options = with types; {
    davids.brew = {
      enable = mkEnableOption "Homebrew integration";
      prefix = mkOption {
        type = str;
        default = "/opt/homebrew";
        description = "Homebrew installation prefix";
      };
    };
  };

  config.programs.zsh.envExtra = mkIf brew.enable ''
    export HOMEBREW_PREFIX="${brew.prefix}"
    export PATH="${brew.prefix}/bin:$PATH"
  '';

  config.programs.zsh.initExtra = mkIf brew.enable ''
    if type brew &>/dev/null; then
      FPATH=$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH
      autoload -Uz compinit
      compinit
    fi
  '';

  config.programs.bash.profileExtra = mkIf brew.enable ''
    export HOMEBREW_PREFIX="${brew.prefix}"
    export PATH="${brew.prefix}/bin:$PATH"
  '';

  config.programs.bash.bashrcExtra = mkIf brew.enable ''
    if [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
      source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
    else
      for COMPLETION in "$HOMEBREW_PREFIX/etc/bash_completion.d/"*; do
        [[ -r "''${COMPLETION}" ]] && source "''${COMPLETION}"
      done
    fi
  '';
}