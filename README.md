# Dotfiles

Stow-based dotfiles with a full-bootstrap installer for macOS and Linux.

## Quick Start

```bash
git clone https://github.com/portableprogrammer/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is idempotent — safe to re-run on an already-configured machine.

## What It Does

The installer handles everything a fresh machine needs:

1. **Package manager & dependencies** — Homebrew (macOS) or apt (Linux), plus stow, fd, fastfetch, nano, git, zsh, and more
2. **Shell framework** — Oh-My-Zsh and Powerlevel10k (skipped if already installed)
3. **Stow dotfiles** — Symlinks `common` (always) and `mac` (macOS only) packages into `$HOME`
4. **Platform extras** (macOS) — Installs fonts, imports Terminal.app theme, optionally applies system defaults
5. **Shell switch** — Sets zsh as the default shell if it isn't already

## Directory Structure

```
dotfiles/
├── common/                          # stow package: all platforms
│   ├── .bashrc                      # Bash initialization (fallback shell)
│   ├── .bash_aliases                # Bash aliases
│   ├── .zshrc                       # Zsh entry point (loads .zshrc.d/*.sh)
│   ├── .zshenv                      # Zsh environment (EDITOR=nano)
│   ├── .p10k.zsh                    # Powerlevel10k theme config
│   ├── .screenrc                    # GNU Screen settings
│   ├── .nanorc                      # Nano editor config
│   ├── .hushlogin                   # Suppress login banners
│   ├── .zshrc.d/                    # Modular zsh scripts (loaded in order)
│   │   ├── 010_screen.sh            # Auto-attach screen on SSH
│   │   ├── 011_neofetch.sh          # Run fastfetch on login
│   │   ├── 100_main.sh              # Oh-My-Zsh + Powerlevel10k setup
│   │   ├── 110_aliases.sh           # Shell aliases
│   │   ├── 200_bindings.sh          # HOME/END key bindings
│   │   └── 900_p10k.sh              # Load Powerlevel10k config
│   └── .config/
│       └── fastfetch/
│           └── config.jsonc         # Fastfetch display config
├── mac/                             # stow package: macOS only
│   └── .zshrc.d/
│       ├── 898_mac_env.sh           # 1Password SSH agent
│       └── 899_mac_aliases.sh       # macOS-specific aliases
├── resources/
│   ├── fonts/                       # MesloLGS Nerd Font (4 variants)
│   └── Smyck.terminal              # Terminal.app color theme
├── scripts/
│   └── macos-defaults.sh           # macOS system defaults (~300 settings)
└── install.sh                       # Full bootstrap entry point
```

## Manual Usage

```bash
# Symlink common dotfiles
stow -d ~/dotfiles -t ~ common

# Symlink macOS dotfiles (in addition to common)
stow -d ~/dotfiles -t ~ mac

# Remove symlinks
stow -D -d ~/dotfiles -t ~ common

# Dry run (preview what would be linked)
stow -n -v -d ~/dotfiles -t ~ common
```

## Customization

### .zshrc.d Modules

Shell configuration is split into numbered modules that load in sorted order. Use the numbering scheme to control load order:

| Range | Purpose | Examples |
|-------|---------|----------|
| `0xx` | Early initialization | Screen auto-attach, system info display |
| `1xx` | Framework & aliases | Oh-My-Zsh setup, shell aliases |
| `2xx` | Bindings & completion | Key bindings, tab completion |
| `8xx` | Platform-specific | macOS environment, macOS aliases |
| `9xx` | Final setup | Powerlevel10k prompt |

To add a new module, create a `.sh` file in the appropriate `common/.zshrc.d/` or `mac/.zshrc.d/` directory with a number that places it in the right loading order.

### Key Aliases

| Alias | Platform | Description |
|-------|----------|-------------|
| `la` | All | Detailed file listing |
| `update` | Linux | Full apt update/upgrade/autoremove/clean |
| `update` | macOS | Software Update + Homebrew update |
| `brewup` | macOS | Homebrew update/upgrade/autoremove/cleanup |
| `treesize` | All | Interactive disk usage (ncdu) |
| `neofetch` | All | System info (fastfetch) |
| `extip` | macOS | External IP address |
| `localip` | macOS | Local IP address |

## Platform Notes

### macOS

- **Fonts**: MesloLGS Nerd Font is copied to `~/Library/Fonts/` for Powerlevel10k glyph rendering
- **Terminal theme**: Smyck.terminal is imported into Terminal.app
- **System defaults**: `scripts/macos-defaults.sh` applies ~300 macOS preferences (Finder, Dock, Safari, etc.) — requires a reboot after running

### Linux

- **Debian Buster**: The installer automatically comments out unsupported `.nanorc` options (`indicator`, `minibar`)
- **Ubuntu < 24.10**: The fastfetch PPA is added automatically since the package isn't in the default repos

## Prerequisites

The installer handles all dependencies automatically. If you prefer manual setup, you'll need:

- `stow` — GNU Stow for symlink management
- `zsh` — Z shell
- `git` — For cloning Oh-My-Zsh and Powerlevel10k
- `fd` / `fd-find` — Used by `.zshrc` to discover `.zshrc.d/` modules
- `fastfetch` — System info display on login
