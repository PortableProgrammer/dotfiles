#!/usr/bin/env bash
set -euo pipefail

# ─── Dock Configuration ──────────────────────────────────────────────────────
# Sets Dock contents programmatically via dockutil.
# Run after applications are installed (e.g. after brew bundle).

if ! command -v dockutil &>/dev/null; then
    echo "dockutil not found — install via: brew install dockutil"
    exit 1
fi

echo "Configuring Dock..."

# Remove all existing items
dockutil --remove all --no-restart

# ─── Apps ─────────────────────────────────────────────────────────────────────

dockutil --add "/Applications/Google Chrome.app" --no-restart
dockutil --add "/Applications/Visual Studio Code - Insiders.app" --no-restart
dockutil --add "/System/Applications/System Settings.app" --no-restart

# ─── Apply ────────────────────────────────────────────────────────────────────

killall Dock
echo "Dock configured."
