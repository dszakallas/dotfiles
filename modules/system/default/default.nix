{
  overlays,
  ...
}:
{
  lib,
  ...
}:
{
  nixpkgs.overlays = [
    overlays
  ];
}
