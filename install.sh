#!/usr/bin/env bash
set -euo pipefail

# ─── Dotfiles Bootstrap ──────────────────────────────────────────────────────
# Idempotent installer — safe to re-run on an already-configured machine.
# Usage: git clone <repo> ~/dotfiles && cd ~/dotfiles && ./install.sh

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Helpers ──────────────────────────────────────────────────────────────────

info()  { printf '\033[1;34m[info]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[ok]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[warn]\033[0m  %s\n' "$*"; }
err()   { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

is_macos() { [[ "$OSTYPE" == darwin* ]]; }
is_linux() { [[ "$OSTYPE" == linux* ]]; }

# ─── Sudo keep-alive ────────────────────────────────────────────────────────

# Ask for the administrator password upfront (needed by brew casks, apt, chsh)
sudo -v

# Keep-alive: update existing sudo timestamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ─── Phase 1: Package manager & dependencies ─────────────────────────────────

info "Phase 1: Package manager & dependencies"

if is_macos; then
    # Trigger Xcode Command Line Tools install if missing. Non-blocking —
    # this surfaces the GUI dialog without halting the script. If CLT
    # isn't installed by the time Homebrew runs, brew install will fail
    # for formulae that need a compiler. The dialog is harmless if CLT
    # is already present.
    if ! xcode-select -p &>/dev/null; then
        info "Triggering Xcode Command Line Tools install dialog (click Install in the popup)..."
        xcode-select --install 2>/dev/null || true
        warn "Wait for the CLT install dialog to complete before re-running this script if anything fails below."
    fi

    # Install Homebrew if missing
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for the rest of this script
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        ok "Homebrew already installed"
    fi

    info "Installing Homebrew packages from Brewfile..."
    # Tolerate partial failure so Phases 2-5 can still run. Common reasons
    # individual Brewfile entries fail on a fresh machine:
    #  - App Store not signed in via the GUI (mas entries error with
    #    "Unknown Error" — open App Store.app, sign in, re-run this script)
    #  - swiftlint requires a full Xcode.app (install via App Store
    #    after this script completes, then re-run for the swiftlint pickup)
    #  - Some .pkg casks (docker-desktop, wireshark, microsoft-office,
    #    logi-options+) trigger their own Authorization Services password
    #    prompts which sudo keep-alive does NOT cover
    brew bundle --file="$DOTFILES_DIR/Brewfile" || \
        warn "Some Brewfile entries failed to install. See output above. Continuing to subsequent phases; re-run install.sh after addressing the failures (e.g. App Store sign-in) to retry."

elif is_linux; then
    # Add fastfetch PPA on older Ubuntu
    if command -v lsb_release &>/dev/null; then
        distro=$(lsb_release -si)
        version=$(lsb_release -sr)

        if [[ "$distro" == "Ubuntu" ]] && dpkg --compare-versions "$version" lt "24.10"; then
            if [[ ! -f /usr/share/keyrings/fastfetch-repo-keyring.asc ]]; then
                info "Adding fastfetch PPA for Ubuntu < 24.10..."
                FASTFETCH_SIG="eb65ee19d802f3eb1a13cfe47e2e5cb4d4865f21"
                sudo curl -fsSL \
                    "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${FASTFETCH_SIG}" \
                    -o /usr/share/keyrings/fastfetch-repo-keyring.asc
                CODENAME=$(lsb_release -sc)
                echo "deb [signed-by=/usr/share/keyrings/fastfetch-repo-keyring.asc] https://ppa.launchpadcontent.net/zhangsongcui3371/fastfetch/ubuntu ${CODENAME} main" \
                    | sudo tee /etc/apt/sources.list.d/fastfetch.list >/dev/null
            else
                ok "fastfetch PPA already configured"
            fi
        fi
    fi

    info "Installing packages via apt..."
    sudo apt update -y
    sudo apt install -y stow fd-find fastfetch nano git zsh screen ncdu fzf
else
    err "Unsupported platform: $OSTYPE"
    exit 1
fi

ok "Phase 1 complete"

# ─── Phase 2: Shell framework ────────────────────────────────────────────────

info "Phase 2: Shell framework (Oh-My-Zsh + Powerlevel10k)"

# Install Oh-My-Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" \
        --unattended --keep-zshrc
else
    ok "Oh-My-Zsh already installed"
fi

# Install Powerlevel10k
P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    ok "Powerlevel10k already installed"
fi

ok "Phase 2 complete"

# ─── SSH signing key (macOS) ────────────────────────────────────────────────

if is_macos; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    SSH_PUB="$HOME/.ssh/id_ed25519.pub"
    ALLOWED_SIGNERS="$HOME/.ssh/allowed_signers"
    SIGNING_PRINCIPAL="nick@warnerheavyindustries.com"

    if [[ ! -f "$SSH_PUB" ]] || [[ ! -f "$ALLOWED_SIGNERS" ]]; then
        info "Fetching SSH signing key from GitHub..."
        SIGNING_KEY=$(curl -fsSL https://api.github.com/users/PortableProgrammer/ssh_signing_keys \
            | jq -r '.[0].key')
        if [[ -z "$SIGNING_KEY" || "$SIGNING_KEY" == "null" ]]; then
            warn "Could not fetch SSH signing key from GitHub — git commit signing may not work"
        else
            if [[ ! -f "$SSH_PUB" ]]; then
                echo "$SIGNING_KEY" > "$SSH_PUB"
                chmod 644 "$SSH_PUB"
                ok "SSH signing public key installed"
            fi
            if [[ ! -f "$ALLOWED_SIGNERS" ]]; then
                echo "$SIGNING_PRINCIPAL namespaces=\"git\" $SIGNING_KEY" > "$ALLOWED_SIGNERS"
                chmod 644 "$ALLOWED_SIGNERS"
                ok "Allowed signers file installed (enables local git verify-commit)"
            fi
        fi
    else
        ok "SSH signing key and allowed signers already in place"
    fi
fi

# ─── Phase 3: Stow dotfiles ──────────────────────────────────────────────────

info "Phase 3: Stow dotfiles"

stow -d "$DOTFILES_DIR" -t "$HOME" common
ok "Stowed 'common' package"

if is_macos; then
    stow -d "$DOTFILES_DIR" -t "$HOME" mac
    ok "Stowed 'mac' package"
fi

ok "Phase 3 complete"

# ─── Phase 4: Platform extras (macOS only) ───────────────────────────────────

if is_macos; then
    info "Phase 4: macOS extras"

    # Copy fonts
    info "Installing fonts to ~/Library/Fonts..."
    cp "$DOTFILES_DIR"/resources/fonts/*.ttf "$HOME/Library/Fonts/" 2>/dev/null || true
    ok "Fonts installed"

    # Import Smyck terminal theme
    info "Importing Smyck.terminal theme..."
    open "$DOTFILES_DIR/resources/Smyck.terminal" 2>/dev/null || true
    defaults write com.apple.terminal "Default Window Settings" -string "Smyck" 2>/dev/null || true
    defaults write com.apple.Terminal "Startup Window Settings" -string "Smyck" 2>/dev/null || true
    ok "Smyck.terminal imported and configured as default and startup theme"

    # Configure Dock
    echo ""
    read -rp "Configure Dock layout? This will replace all current Dock items. [y/N] " run_dock
    if [[ "$run_dock" =~ ^[Yy]$ ]]; then
        info "Configuring Dock..."
        bash "$DOTFILES_DIR/scripts/dock.sh"
        ok "Dock configured"
    else
        info "Skipped Dock setup (run manually: ./scripts/dock.sh)"
    fi

    # macOS defaults (optional, prompts first)
    echo ""
    read -rp "Run macOS system defaults? This changes many settings and may require a reboot. [y/N] " run_defaults
    if [[ "$run_defaults" =~ ^[Yy]$ ]]; then
        info "Running macOS defaults..."
        bash "$DOTFILES_DIR/scripts/macos-defaults.sh"
        ok "macOS defaults applied — a reboot is recommended"
    else
        info "Skipped macOS defaults (run manually: ./scripts/macos-defaults.sh)"
    fi

    ok "Phase 4 complete"
fi

# ─── Phase 5: Shell switch ───────────────────────────────────────────────────

info "Phase 5: Default shell"

CURRENT_SHELL=$(basename "$SHELL")
if [[ "$CURRENT_SHELL" != "zsh" ]]; then
    info "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
    ok "Default shell changed to zsh — open a new terminal to use it"
else
    ok "Default shell is already zsh"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
ok "Dotfiles bootstrap complete!"
info "Open a new terminal session to load the new configuration."
echo ""
info "Manual steps remaining:"
info "  1. 1Password — Sign in and configure"
info "  2. iStat Menus — Enter license key and import settings from resources/"
info "  3. TestFlight — Open and install beta apps (e.g. UniFi)"
info "  4. Shortcuts — Import 'Open Google Chrome Profile' shortcut and add to Dock"
