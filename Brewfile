# ─── Taps ─────────────────────────────────────────────────────────────────────

tap "fluxcd/tap"

# ─── Formulae ─────────────────────────────────────────────────────────────────

# Shell & dotfiles
brew "fastfetch"
brew "fd"
brew "git"
brew "nano"
brew "ncdu"
brew "stow"
brew "zsh"

# Homelab / infrastructure
brew "ansible"
brew "ansible-lint"
brew "fluxcd/tap/flux"
brew "helm"
brew "k9s"
brew "kubernetes-cli"
brew "powershell"
brew "pre-commit"
brew "sops"
brew "teleport"

# Development
brew "gh"
brew "shellcheck"
brew "swiftlint"

# Utilities
brew "dockutil"
brew "gnupg"
brew "httpie"
brew "jq"
brew "libsmi"  # SMI/MIB parsing — backs Wireshark's SNMP dissector and homelab MIB work
brew "mas"
brew "mole"  # https://mole.fit — macOS cleanup/optimize CLI
brew "nmap"
brew "socat"
brew "watch"
brew "yq"

# ─── Casks ────────────────────────────────────────────────────────────────────

# Browsers
cask "google-chrome"

# Communication
cask "slack"

# Development
cask "claude"
# cask "claude-code"  # 2026-07-30: dropped. The CLI comes from Anthropic's native
#   installer (install.sh Phase 3b → ~/.local/bin/claude), which auto-updates in the
#   background. The Homebrew casks explicitly do NOT auto-update — you'd have to run
#   `brew upgrade claude-code` by hand. Two casks exist if you ever want to switch:
#   `claude-code` (stable channel, ~1 week behind) and `claude-code@latest`.
cask "coteditor"  # moved from mas 2026-05-22 — same binary, brew installs reproducibly on VMs where App Store is unreachable
cask "docker-desktop"
# cask "powershell"  # 2026-05-22: removed from homebrew-cask; only powershell@preview remains, and it's deprecated (Gatekeeper check fails, disabled 2026-09-01). Install manually from https://github.com/PowerShell/PowerShell/releases if needed.
cask "royal-tsx"
cask "visual-studio-code@insiders"
cask "wireshark-app"  # 2026-05-23: renamed upstream from 'wireshark' to 'wireshark-app'

# Productivity
cask "microsoft-office"  # bundles OneDrive — do NOT also list cask "onedrive" (conflicts)
cask "transmit"

# Security
cask "1password"
cask "1password-cli"

# System monitoring
cask "istat-menus"

# System utilities
cask "appcleaner"
cask "jordanbaird-ice"
cask "logi-options+"
cask "monitorcontrol"
cask "qlmarkdown"
cask "the-unarchiver"  # moved from mas 2026-05-22 — same binary, brew installs reproducibly on VMs where App Store is unreachable

# ─── Mac App Store ────────────────────────────────────────────────────────────

mas "1Password for Safari", id: 1569813296
mas "AdGuard for Safari", id: 1440147259
mas "Codye", id: 1516894961
mas "DaisyDisk", id: 411643860
mas "DevCleaner", id: 1388020431
mas "Discovery", id: 1381004916
mas "Magnet", id: 441258766
mas "TestFlight", id: 899247664
mas "Userscripts", id: 1463298887
mas "Xcode", id: 497799835

# WiFiman (id 1385561119) is an iOS app run on Apple Silicon via "Designed for
# iPad", not a Mac app. `mas` can neither list nor install iOS apps, so a `mas`
# line here is permanently unsatisfiable — `brew bundle check` would fail forever.
# Install by hand: App Store → search "WiFiman" → "iPhone & iPad Apps" tab.
# Tracked as a manual step in FIRST-RUN.md.
