{
  overlays,
  ...
}:
{
  lib,
  ...
}:
{
  services.openssh.extraConfig = ''
    PasswordAuthentication no
    ChallengeResponseAuthentication no
  '';

  nixpkgs.overlays = [
    overlays
  ];
}
