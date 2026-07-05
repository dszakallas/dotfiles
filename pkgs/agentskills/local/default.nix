{
  mkSkill,
  exclude ? null,
  include ? null,
}:
mkSkill {
  name = "davids-dotfiles-skills";
  version = "unstable";
  src = ./.;
  inherit include exclude;
}
