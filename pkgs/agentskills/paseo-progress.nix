{
  fetchFromGitHub,
  mkSkill,
  include ? null,
  exclude ? null,
}:
mkSkill {
  name = "paseo-progress";
  version = "1.8.0";
  src = fetchFromGitHub {
    owner = "stevecastaneda";
    repo = "paseo-plugins";
    rev = "0cbe39cc953f67415407c602c7f865eedcd76461";
    hash = "sha256-tmoRIY5qPDbY1Yk4/dlOaC1/llWHwXVF8acyMdJZ4Ec=";
  };
  sourceRoot = "progress";
  inherit include exclude;
}
