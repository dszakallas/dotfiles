# Prelude contains common, unopinionated overlays
# that makes it easier to use functions depending on other packages.
{ davids-dotfiles-common, ... }:
fix: prev: {
  mkSkill = davids-dotfiles-common.lib.agents.mkSkill { inherit (fix) stdenvNoCC yq-go; };
}
