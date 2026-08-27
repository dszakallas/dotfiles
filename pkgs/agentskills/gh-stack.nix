{
  fetchFromGitHub,
  mkSkill,
}:
mkSkill {
  name = "gh-stack";
  version = "2026-08-26";
  src = fetchFromGitHub {
    owner = "github";
    repo = "gh-stack";
    rev = "5fe0a50cceb6835a6529d237b8141ae7907a8ebd";
    hash = "sha256-5m0DWsDo1zaag6GaTbTlMi3/Aw6rY0/Z2O1d3T4y36g=";
  };
}
