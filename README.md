# Dotfiles

Stow-based dotfiles with a full-bootstrap installer for macOS and Linux.

## Quick Start

```bash
git clone https://github.com/PortableProgrammer/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Then **follow [FIRST-RUN.md](FIRST-RUN.md) from the top.** It walks the full setup linearly: pre-install gates (App Store sign-in, Xcode CLT, Terminal permissions), running `./install.sh` itself, then post-install identity bootstrap (1Password, GitHub CLI, container runtime, macOS permissions, network, per-project handoff).

`install.sh` is idempotent — safe to re-run on an already-configured machine, and safe to re-run after a partial failure to pick up where it left off.

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
│       ├── 897_brew_drift.sh        # Warns when brew install/uninstall diverges from Brewfile
│       ├── 898_mac_env.sh           # 1Password SSH agent
│       └── 899_mac_aliases.sh       # macOS-specific aliases
├── resources/
│   ├── fonts/                       # MesloLGS Nerd Font (4 variants)
│   ├── iStat Menus Settings *.ismp7 # iStat Menus settings backup (manual import)
│   └── Smyck.terminal               # Terminal.app color theme
├── scripts/
│   ├── dock.sh                      # Dock layout configuration (via dockutil)
│   └── macos-defaults.sh            # macOS system defaults (~300 settings)
├── bin/
│   ├── brew-drift.sh                # Read-only Brewfile drift report (both directions)
│   └── verify-workstation.sh        # Post-bootstrap sanity check (FIRST-RUN §12)
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
| `8xx` | Platform-specific | Brewfile drift warning, macOS environment, macOS aliases |
| `9xx` | Final setup | Powerlevel10k prompt |

To add a new module, create a `.sh` file in the appropriate `common/.zshrc.d/` or `mac/.zshrc.d/` directory with a number that places it in the right loading order.

### Key Aliases

| Alias | Platform | Description |
| ------- | ---------- | ------------- |
| `la` | All | Detailed file listing |
| `update` | Linux | Full apt update/upgrade/autoremove/clean |
| `update` | macOS | Software Update + Homebrew update |
| `brewup` | macOS | Homebrew + App Store update/upgrade/autoremove/cleanup, then a drift report |
| `brewup-deep` | macOS | Force auto-updating casks onto the cask's version (`--greedy`) |
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

### Brewfile conventions

The Brewfile records **intent** — what a machine built from this repo should have. That is why nothing auto-writes it, and why a package you are still evaluating is legitimately undeclared.

**Prefer a `cask` over `mas` when the same binary ships both ways.** Homebrew installs reproducibly on VMs and fresh machines where the App Store is unreachable or not signed in; `mas` requires an Apple ID that has already obtained the app. CotEditor and The Unarchiver both moved from `mas` to `cask` on this basis (2026-05-22). Use `mas` only where there is no cask.

Inline comments are reserved for constraints that bite *while editing the file* — a conflict, or a non-obvious reason a package exists. Two currently qualify:

- `microsoft-office` bundles OneDrive, so adding `cask "onedrive"` alongside it conflicts.
- `libsmi` looks unused but backs Wireshark's SNMP dissector and homelab MIB work.

### Deliberately not in the Brewfile

Absences are decisions too, and they are invisible in a file that only lists what is present.

| Package | Why it is absent |
| --------- | ------------------ |
| `claude-code` | The CLI comes from Anthropic's native installer (`install.sh` Phase 3b → `~/.local/bin/claude`), which auto-updates in the background. Both Homebrew casks explicitly do **not** auto-update, so they would need a manual `brew upgrade`. If you ever want to switch, the casks are `claude-code` (stable, ~1 week behind) and `claude-code@latest`. The `claude` cask *is* declared — that is the desktop app, a different thing. |
| `powershell` (cask) | Removed from homebrew-cask 2026-05-22; only the deprecated `powershell@preview` remains, whose Gatekeeper check fails and which is disabled from 2026-09-01. Declared as a **formula** instead. Install manually from [PowerShell releases](https://github.com/PowerShell/PowerShell/releases) if the formula ever goes too. |
| `onedrive` | Already bundled by `microsoft-office`; declaring both conflicts. |

### Checking for drift

`brew` does not update the Brewfile when you install something by hand, so the two diverge silently. [`bin/brew-drift.sh`](bin/brew-drift.sh) reports every direction the machine and the Brewfile can disagree — read-only, it never installs or removes anything:

```bash
./bin/brew-drift.sh
```

| Direction | Meaning | Failure mode |
| ----------- | --------- | -------------- |
| Installed but undeclared | You `brew install`ed it and never added it | Lost on the next machine, or deleted by `brew bundle cleanup` |
| Declared but unsatisfied | The Brewfile names something brew doesn't manage — usually an app installed by hand into `/Applications` | **Silent** — works here, missing on rebuild |
| Stale on disk | Declared, installed, brew says current — but the app bundle is older than the cask | **Silent, and invisible to every other brew command** |
| App Store outdated | A `mas` app has an update waiting | Nothing else surfaces it; `brew bundle check` calls it "not installed" |
| Orphaned dependencies | Left behind after uninstalling a formula | Slow accretion |

The stale-on-disk check exists because brew's own records can be fiction. `brew install --cask --adopt` writes a Caskroom entry named for the cask's *current* version without inspecting the app it adopted, so `brew outdated` and `brew upgrade --greedy` compare that record against the cask, find them equal, and skip the app permanently. Verified 2026-08-04: Google Chrome sat nineteen months stale at 132.0.6834.84 while brew recorded 151.0.7922.72. The check reads `CFBundleShortVersionString` from the bundle instead — the only version here that is observed rather than asserted. Casks with no `.app` artifact (pkg, binary, prefpane) are listed as unchecked rather than passed over silently.

Only packages installed *on request* count — dependencies are correctly ignored, so you never declare a package's dep tree. Exits `1` on drift, so it works as a gate; `--quiet` suppresses output for hook use.

For an app that already exists in `/Applications` but isn't brew-managed, adopt rather than reinstall:

```bash
brew install --cask --adopt <name>
```

#### Drift warnings at the keyboard

[`mac/.zshrc.d/897_brew_drift.sh`](mac/.zshrc.d/897_brew_drift.sh) wraps `brew` and speaks up the moment an interactive install or uninstall diverges from the Brewfile:

```
$ brew install knockknock
[brewfile] knockknock installed but not declared — add: brew "knockknock"
[brewfile] ~/Code/dotfiles/Brewfile — nothing was written; a trial install needs no entry
```

**It never writes the Brewfile.** Declaring is a decision about intent, and a package you are still evaluating is legitimately undeclared — the module header records why auto-editing was rejected, and which of the original arguments for that turned out not to hold.

The wrapper only sees what you type interactively; installs from `install.sh`, Ansible, or any script bypass it entirely. So drift reaches you through three channels, each timed to arrive when it costs the least attention:

| Channel | Fires | Carries |
| --------- | ------- | --------- |
| `brew` wrapper (`897`) | The instant you install or uninstall | One line, about the thing you just did |
| `brewup` tail (`899`) | Every update run | The full five-section report |
| Staleness nag (`897`) | Shell start, only when overdue | That the check itself hasn't run |

The report tails `brewup` rather than greeting you at shell start on purpose: a terminal is opened *holding a task*, and a report printed there competes with it. `brewup` is already the housekeeping ritual, so the findings land when package state is what you're thinking about anyway.

That leaves one blind spot — the ritual lapsing — which is the nag's entire job. It stays silent until the check is over `BREW_DRIFT_MAX_DAYS` old (default 21), then prints one line at most once a day. A check nobody runs reports nothing, which reads exactly like a clean machine.

Silence all of it for a session with `BREW_DRIFT_WARN=0`.

### Formulae

| Category | Packages |
| ---------- | ---------- |
| Shell & dotfiles | fastfetch, fd, git, nano, ncdu, stow, zsh |
| Homelab / infra | ansible, ansible-lint, fluxcd/tap/flux, helm, k9s, kubernetes-cli, powershell, pre-commit, sops, teleport |
| Development | gh, shellcheck, swiftlint |
| Utilities | dockutil, gnupg, httpie, jq, libsmi, mas, mole, nmap, socat, watch, yq |

### Casks

| Category | Applications |
| ---------- | ------------- |
| Browsers | google-chrome |
| Communication | slack |
| Development | claude, coteditor, docker-desktop, royal-tsx, visual-studio-code@insiders, wireshark-app |
| Productivity | microsoft-office, transmit |
| Security | 1password, 1password-cli |
| System monitoring | istat-menus |
| System utilities | appcleaner, jordanbaird-ice, logi-options+, monitorcontrol, qlmarkdown, the-unarchiver |

### Mac App Store (via `mas`)

| App | ID |
| ----- | ---- |
| 1Password for Safari | 1569813296 |
| AdGuard for Safari | 1440147259 |
| Codye | 1516894961 |
| DaisyDisk | 411643860 |
| DevCleaner | 1388020431 |
| Discovery | 1381004916 |
| Magnet | 441258766 |
| TestFlight | 899247664 |
| Userscripts | 1463298887 |
| Xcode | 497799835 |

**Note:** Mac App Store apps require being signed in and having previously obtained the app (including free apps).

### Deliberately not in the Brewfile

| Thing | Why |
| ------- | ----- |
| Claude Code CLI | Installed by Anthropic's native installer in `install.sh` Phase 3b, which auto-updates in the background. The `claude-code` cask does not auto-update. |
| WiFiman | An iOS app run on Apple Silicon via "Designed for iPad". `mas` can neither list nor install iOS apps, so a `mas` line would be permanently unsatisfiable. Install from the App Store's "iPhone & iPad Apps" tab. |
| PowerShell cask | Removed from homebrew-cask upstream; the `powershell` **formula** is used instead. |

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
