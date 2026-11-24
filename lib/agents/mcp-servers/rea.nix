pkgs: {
  type = "stdio";
  command = "${pkgs.rea}/bin/rea";
  args = [ "--mcp" ];
  env = {
    GHIDRA_INSTALL_DIR = "${pkgs.ghidra-bin}/lib/ghidra";
  };
}
