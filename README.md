# dotfiles

My personal dotfiles as a flake.

> [!NOTE]  
> Most of my reusable config can be found in [bikeshed](https://github.com/dszakallas/bikeshed).

Structure:

```text
├── hosts                  # host configurations
├── lib                    # library functions
├── modules
│   ├── darwin             # reusable modules for macOS
│   ├── nixos              # reusable modules for nixOS
│   ├── system             # reusable modules for unix-like systems (nixOS, darwin, etc.)
│   └── home               # reusable modules for home manager
├── overlays               # overlays to be applied to nixpkgs
├── pkgs                   # packages to be called with `bikeshed.lib.callPackageWithRec`
└── users                  # user configurations (can be shared across hosts)
```

Some configurations are not publicly shared, so you need to adjust the flake to your needs.
