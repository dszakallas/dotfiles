# dotfiles

My personal dotfiles as a flake.

Structure:

```
├── hosts                  # host configurations
├── lib                    # library functions
├── modules                       
│   ├── darwin             # reusable modules for macOS
│   └── home               # reusable modules for home manager
├── users                  # user configurations (can be shared across hosts)
└── vendor                 # vendored flake dependencies in git submodules
```

Some configurations are not publicly shared, so you need to adjust the flake to your needs.
