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

# Tolerant add — skip silently if the target doesn't exist. Lets the
# Dock layout configure correctly when some apps are missing (e.g.
# App-Store-sourced apps like CotEditor on a macOS VM where the mas
# block was skipped, or any app the user opted out of installing).
dock_add_app() {
    local app="$1"
    if [[ -d "$app" ]]; then
        dockutil --add "$app" --section apps --no-restart
    else
        echo "  Skipping (not installed): $app"
    fi
}

dock_add_folder() {
    local path="$1"
    if [[ -d "$path" ]]; then
        dockutil --add "$path" --view auto --display folder --section others --no-restart
    else
        echo "  Skipping (does not exist): $path"
    fi
}

# Remove all existing items
dockutil --remove all --no-restart

# ─── Apps (left of separator) ────────────────────────────────────────────────
# Finder is always present and cannot be removed; it stays at position 1.

dock_add_app "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
# "Open Google Chrome Profile" shortcut app must be added manually (see README)
dock_add_app "/Applications/Slack.app"
dock_add_app "/System/Applications/Calendar.app"
dock_add_app "/System/Applications/Mail.app"
dock_add_app "/System/Applications/Messages.app"
dock_add_app "/Applications/CotEditor.app"
dock_add_app "/Applications/Visual Studio Code - Insiders.app"
dock_add_app "/Applications/Claude.app"
dock_add_app "/System/Applications/Utilities/Terminal.app"
dock_add_app "/System/Applications/System Settings.app"

# ─── Folders (right of separator) ────────────────────────────────────────────
# Trash is always present and cannot be removed.

dock_add_folder "/Applications"
dock_add_folder "$HOME/Downloads"

# ─── Apply ────────────────────────────────────────────────────────────────────

killall Dock
echo "Dock configured."
