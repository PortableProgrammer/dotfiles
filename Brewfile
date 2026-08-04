# Declared intent for `brew bundle` — what this machine should have, not what it
# happens to have. Inline notes are for constraints that bite while editing this
# file; standing policy and the reasoning for packages deliberately ABSENT live
# in README.md ("Brewfile conventions" / "Deliberately not in the Brewfile").

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
brew "powershell"  # formula, not cask — the cask was removed upstream 2026-05-22
brew "pre-commit"
brew "age"  # sops' default encryption backend — declared alongside it, not as a dep
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
cask "coteditor"
cask "docker-desktop"
cask "royal-tsx"
cask "visual-studio-code@insiders"
cask "wireshark-app"

# Productivity
cask "microsoft-office"  # bundles OneDrive — do NOT also list cask "onedrive" (conflicts)
cask "obsidian"
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
cask "the-unarchiver"

# ─── Mac App Store ────────────────────────────────────────────────────────────

mas "1Password for Safari", id: 1569813296
mas "AdGuard for Safari", id: 1440147259
mas "Codye", id: 1516894961
mas "DaisyDisk", id: 411643860
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
