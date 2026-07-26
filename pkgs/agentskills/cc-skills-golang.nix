{
  fetchFromGitHub,
  mkSkill,
}:
mkSkill {
  name = "cc-skills-golang";
  version = "2026-07-02";
  src = fetchFromGitHub {
    owner = "samber";
    repo = "cc-skills-golang";
    rev = "8b2d019212d6a5390d472a7660a8489109d7db49";
    hash = "sha256-oSFApXKBndeM1wsl6GyPwiDuIgt5bGXWzDtpnmC6SaM=";
  };
}
