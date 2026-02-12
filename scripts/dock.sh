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

# ─── Apps (left of separator) ────────────────────────────────────────────────
# Finder is always present and cannot be removed; it stays at position 1.

dockutil --add "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app" --section apps --no-restart
# "Open Google Chrome Profile" shortcut app must be added manually (see README)
dockutil --add "/Applications/Slack.app" --section apps --no-restart
dockutil --add "/System/Applications/Calendar.app" --section apps --no-restart
dockutil --add "/System/Applications/Mail.app" --section apps --no-restart
dockutil --add "/System/Applications/Messages.app" --section apps --no-restart
dockutil --add "/Applications/CotEditor.app" --section apps --no-restart
dockutil --add "/Applications/Visual Studio Code - Insiders.app" --section apps --no-restart
dockutil --add "/Applications/Claude.app" --section apps --no-restart
dockutil --add "/System/Applications/Utilities/Terminal.app" --section apps --no-restart
dockutil --add "/System/Applications/System Settings.app" --section apps --no-restart

# ─── Folders (right of separator) ────────────────────────────────────────────
# Trash is always present and cannot be removed.

dockutil --add "/Applications" --view auto --display folder --section others --no-restart
dockutil --add "$HOME/Downloads" --view auto --display folder --section others --no-restart

# ─── Apply ────────────────────────────────────────────────────────────────────

killall Dock
echo "Dock configured."
