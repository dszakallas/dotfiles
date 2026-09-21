{
  fetchFromGitHub,
  mkSkill,
}:
mkSkill {
  name = "paseo-skills";
  version = "2026-09-17";
  src = fetchFromGitHub {
    owner = "getpaseo";
    repo = "paseo";
    rev = "047f40e62356f091a081be6b4b9db32872957d0c";
    hash = "sha256-ECxIoB45sUHil5E2AKOz9ss2bzQL+0y0qLeGwnvAV+4=";
  };
  include = [
    "paseo"
    "paseo-advisor"
    "paseo-committee"
    "paseo-handoff"
    "paseo-help"
    "paseo-plugin"
  ];
}
