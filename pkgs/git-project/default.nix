{
  lib,
  symlinkJoin,
  writeShellApplication,
  installShellFiles,
  git,
  coreutils,
  bd,
}:

let
  bin = writeShellApplication {
    name = "git-project";
    runtimeInputs = [
      git
      coreutils
      bd
    ];
    text = builtins.readFile ./git-project.sh;
  };
in
symlinkJoin {
  name = "git-project";
  paths = [ bin ];
  nativeBuildInputs = [ installShellFiles ];
  postBuild = ''
    installManPage ${./git-project.1}
    installShellCompletion --bash --name git-project ${./completions/git-project.bash}
    installShellCompletion --zsh --name _git-project ${./completions/_git-project}
    installShellCompletion --fish --name git-project.fish ${./completions/git-project.fish}
  '';
  meta = with lib; {
    description = "Git project utility for managing bare repositories, agent worktrees, and beads";
    mainProgram = "git-project";
  };
}
