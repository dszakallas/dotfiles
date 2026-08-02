# Prelude contains common, unopinionated overlays
# that makes it easier to use functions depending on other packages.
{ bikeshed, ... }:
fix: prev: {
  mkSkill = bikeshed.lib.agents.mkSkill { inherit (fix) stdenvNoCC yq-go; };
}
