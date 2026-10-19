{
  fetchFromGitHub,
  mkSkill,
  include ? null,
  exclude ? null,
}:
mkSkill {
  name = "paseo-progress";
  version = "1.3.1";
  src = fetchFromGitHub {
    owner = "stevecastaneda";
    repo = "paseo-plugins";
    rev = "8ace23617207c47fdb809d87ebc75895a7405e75";
    hash = "sha256-IeggA8zfQMCZFumei/fyEmtLVF/2VrbeZHq7cs9EJdM=";
  };
  sourceRoot = "progress";
  inherit include exclude;
}
