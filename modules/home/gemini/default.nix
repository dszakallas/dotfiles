{ ... }:
{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [ gemini-cli ];
  home.sessionVariables = {
    GEMINI_SANDBOX = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "sandbox-exec";
  };
}
