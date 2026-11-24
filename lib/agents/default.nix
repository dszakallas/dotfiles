{
  mcpServers = {
    open-pencil = import ./mcp-servers/open-pencil.nix;
    rea = import ./mcp-servers/rea.nix;
  };
  memory = {
    avoidTropes = builtins.readFile ./memory/avoid-tropes.md;
    codingWorkflow = builtins.readFile ./memory/coding-workflow.md;
    audiences = builtins.readFile ./memory/audiences.md;
    machineUse = builtins.readFile ./memory/machine-use.md;
    worktrees = builtins.readFile ./memory/worktrees.md;
  };
}
