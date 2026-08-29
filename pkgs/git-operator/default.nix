{
  lib,
  writeShellApplication,
  git,
  coreutils,
}:

writeShellApplication {
  name = "git-operator";
  runtimeInputs = [
    git
    coreutils
  ];
  text = builtins.readFile ./git-operator.sh;
  meta = with lib; {
    description = "Git operator utility for managing bare repositories and agent worktrees";
    mainProgram = "git-operator";
  };
}
