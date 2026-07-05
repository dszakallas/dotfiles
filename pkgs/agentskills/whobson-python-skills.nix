{
  fetchFromGitHub,
  mkSkill,
  exclude ? null,
  include ? null,
}:
mkSkill {
  name = "wshobson-python-skills";
  version = "2026-06-25";
  src = fetchFromGitHub {
    owner = "wshobson";
    repo = "agents";
    rev = "5cc2549a50fc672230efd0a0307e2fd27ffba792";
    hash = "sha256-wgDN0ytDleqyPQtJHSvrzZVSeY+JPI+SNDl3FFliIqM=";
  };
  subDir = "plugins/python-development";
  inherit include exclude;
}
