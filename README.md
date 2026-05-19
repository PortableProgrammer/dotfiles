# Dotfiles

Stow-based dotfiles with a full-bootstrap installer for macOS and Linux.

## Quick Start

```bash
git clone https://github.com/PortableProgrammer/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is idempotent — safe to re-run on an already-configured machine.

> [!NOTE]
> **Forking this repo?** The `mac/` package is personalized:
>
> - [mac/.gitconfig](mac/.gitconfig) hardcodes my git identity (name, email, signing key path).
> - [install.sh](install.sh) fetches *my* SSH signing public key from GitHub's API.
>
> Swap these for your own values before stowing, or you'll try to commit as me. The `common/` package is portable and doesn't need changes.

## What It Does

The installer handles everything a fresh machine needs:

1. **Package manager & dependencies** — Homebrew (macOS) or apt (Linux), including all formulae, casks, and CLI tools
2. **Shell framework** — Oh-My-Zsh and Powerlevel10k (skipped if already installed)
3. **SSH signing key** (macOS) — Fetches your SSH signing public key from GitHub's API for git commit signing
4. **Stow dotfiles** — Symlinks `common` (always) and `mac` (macOS only) packages into `$HOME`
5. **Platform extras** (macOS) — Installs fonts, imports Terminal.app theme, configures Dock, optionally applies system defaults
6. **Shell switch** — Sets zsh as the default shell if it isn't already

## Directory Structure

```shell
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
│   ├── .claude/                     # Claude Code global config
│   │   ├── CLAUDE.md                # Global AI assistant preferences
│   │   ├── settings.json            # Statusline configuration
│   │   └── statusline-command.sh    # Custom statusline script
│   ├── .gitconfig                   # Git identity, signing, and pull config
│   ├── .ssh/
│   │   └── config                   # SSH config (1Password agent)
│   └── .zshrc.d/
│       ├── 898_mac_env.sh           # 1Password SSH agent
│       └── 899_mac_aliases.sh       # macOS-specific aliases
├── resources/
│   ├── fonts/                       # MesloLGS Nerd Font (4 variants)
│   ├── iStat Menus Settings *.ismp7 # iStat Menus settings backup (manual import)
│   └── Smyck.terminal               # Terminal.app color theme
├── scripts/
│   ├── dock.sh                      # Dock layout configuration (via dockutil)
│   └── macos-defaults.sh            # macOS system defaults (~300 settings)
├── Brewfile                         # Homebrew formulae, casks, and App Store apps (macOS)
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
| ------- | --------- | ---------- |
| `0xx` | Early initialization | Screen auto-attach, system info display |
| `1xx` | Framework & aliases | Oh-My-Zsh setup, shell aliases |
| `2xx` | Bindings & completion | Key bindings, tab completion |
| `8xx` | Platform-specific | macOS environment, macOS aliases |
| `9xx` | Final setup | Powerlevel10k prompt |

To add a new module, create a `.sh` file in the appropriate `common/.zshrc.d/` or `mac/.zshrc.d/` directory with a number that places it in the right loading order.

### Key Aliases

| Alias | Platform | Description |
| ------- | ---------- | ------------- |
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
- **Dock layout**: `scripts/dock.sh` sets Dock contents via `dockutil` — run after apps are installed
- **System defaults**: `scripts/macos-defaults.sh` applies macOS preferences (Finder, Dock, Safari, etc.) — requires a reboot after running

### Linux

- **Ubuntu < 24.10**: The fastfetch PPA is added automatically since the package isn't in the default repos

## Homebrew Packages (macOS)

Packages are declared in [`Brewfile`](Brewfile) and installed via `brew bundle`. To add or remove packages, edit the Brewfile and re-run `install.sh` (or `brew bundle --file=~/dotfiles/Brewfile` directly).

### Formulae

| Category | Packages |
| ---------- | ---------- |
| Shell & dotfiles | stow, fd, fastfetch, git, nano, ncdu, zsh |
| Homelab / infra | ansible, ansible-lint, fluxcd/tap/flux, helm, k9s, kubernetes-cli, teleport |
| Development | gh, swiftlint |
| Utilities | dockutil, gnupg, httpie, jq, mas, nmap, socat, watch |

### Casks

| Category | Applications |
| ---------- | ------------- |
| Browsers | google-chrome |
| Communication | slack |
| Development | claude, claude-code, docker-desktop, powershell, royal-tsx, visual-studio-code@insiders, wireshark |
| Gaming | nvidia-geforce-now, steam |
| Productivity | microsoft-office, onedrive, transmit |
| Security | 1password, 1password-cli |
| System monitoring | istat-menus |
| System utilities | appcleaner, jordanbaird-ice, logi-options+, monitorcontrol, qlmarkdown |

### Mac App Store (via `mas`)

| App | ID |
| ----- | ---- |
| 1Password for Safari | 1569813296 |
| AdGuard for Safari | 1440147259 |
| Codye | 1516894961 |
| CotEditor | 1024640650 |
| DaisyDisk | 411643860 |
| Discovery | 1381004916 |
| Magnet | 441258766 |
| TestFlight | 899247664 |
| The Unarchiver | 425424353 |
| Userscripts | 1463298887 |
| WiFiman | 1385561119 |
| Xcode | 497799835 |

**Note:** Mac App Store apps require being signed in and having previously obtained the app (including free apps).

## Post-Install Manual Steps

After `install.sh` completes, the following require manual configuration:

1. **1Password** — Sign in and configure the desktop app. To enable the `op` CLI (used for Ansible vault automation and similar workflows), also turn on "Integrate with 1Password CLI" in 1Password > Settings > Developer. The Safari extension is installed separately via the App Store.
2. **iStat Menus** — Enter your license key, then import settings from `resources/iStat Menus Settings *.ismp7` via iStat Menus > Preferences > Import
3. **TestFlight apps** — Open TestFlight and install any beta apps (e.g. UniFi) that aren't available through the App Store or Homebrew
4. **Open Google Chrome Profile shortcut** — Open Shortcuts.app, import the [Open Google Chrome Profile](https://www.icloud.com/shortcuts/6ea0740784744ecb8f11cebe8580e38a) shortcut, then right-click it > Add to Dock. After the app appears in `~/Applications/`, re-run `./scripts/dock.sh` to place it in the correct Dock position.
5. **macOS defaults** — If you skipped the prompt during install, run `./scripts/macos-defaults.sh` manually and reboot
6. **Dock layout** — If you skipped the prompt during install, run `./scripts/dock.sh` manually after all apps are installed

## Prerequisites

The installer handles all dependencies automatically. If you prefer manual setup, you'll need:

- `stow` — GNU Stow for symlink management
- `zsh` — Z shell
- `git` — For cloning Oh-My-Zsh and Powerlevel10k
- `fd` / `fd-find` — Used by `.zshrc` to discover `.zshrc.d/` modules
- `fastfetch` — System info display on login
