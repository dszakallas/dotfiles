{ self, ... }:
let
  myUsername = "dszakallas";
in
{
  imports = [
    "${self}/modules/darwin"
    "${self}/users/${myUsername}"
  ];

  nix.settings.trusted-users = [ "root" myUsername ];
}
