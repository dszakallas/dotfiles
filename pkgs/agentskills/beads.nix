{
  # nixpkgs ships its own `beads` package, which shadows the same-named flake
  # input here, so reach the input through `self` instead.
  self,
  mkSkill,
  stdenvNoCC,
}:
let
  beads = self.inputs.beads;
in
mkSkill {
  name = "beads";
  version = beads.packages.${stdenvNoCC.hostPlatform.system}.bd.version;
  src = beads;
  sourceRoot = "plugins/beads";
}
