#!/usr/bin/env bash
set -uo pipefail

# ─── brew-drift.sh ───────────────────────────────────────────────────────────
# Read-only Brewfile drift report. Never installs, uninstalls, or edits
# anything — it only tells you where the machine and the Brewfile disagree.
#
# Drift has TWO directions, and they fail in opposite ways:
#
#   installed but undeclared  — you `brew install`ed something and never added
#                               it. Loud failure mode: `brew bundle cleanup`
#                               deletes it on some future machine.
#   declared but unsatisfied  — the Brewfile names something brew doesn't
#                               actually manage (commonly an app installed by
#                               hand into /Applications). SILENT failure mode:
#                               everything works here, and the fresh machine
#                               you rebuild in a year quietly lacks it.
#
# The second is the dangerous one and the one a `brew bundle dump` can never
# fix — a dump records state, so it would "resolve" the disagreement by
# deleting your intent. That's why this script reports and does not write.
#
# It is also STATELESS by design: it compares settled reality against declared
# intent. Packages you installed and removed between runs leave no trace, so
# try-then-discard churn costs nothing here.
#
# Usage: ./brew-drift.sh [--quiet]
# Exit:  0 = no drift, 1 = drift found, 2 = could not run

# ─── Helpers (matches install.sh / verify-workstation.sh idiom) ─────────────

info()  { printf '\033[1;34m[info]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[ok]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[warn]\033[0m  %s\n' "$*"; }
err()   { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1
say() { [[ "$QUIET" -eq 1 ]] || "$@"; }

# ─── Locate the Brewfile (location-independent, like verify-workstation.sh) ──

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# $BREWFILE override exists so this can be pointed at a candidate Brewfile
# (and so the script's own detection can be tested) without editing the repo's.
BREWFILE="${BREWFILE:-$(dirname "$SCRIPT_DIR")/Brewfile}"

if [[ ! -f "$BREWFILE" ]]; then
    err "Brewfile not found at $BREWFILE"
    exit 2
fi

if ! command -v brew &>/dev/null; then
    err "brew not found on PATH — nothing to compare against"
    exit 2
fi

DRIFT=0

say echo ""
say info "Brewfile drift report ($BREWFILE)"
say echo ""

# ─── 1. Declared but unsatisfied ────────────────────────────────────────────
# `brew bundle check` answers "could a fresh `brew bundle install` be a no-op?"
# A cask listed here usually means the app exists in /Applications but was
# installed outside brew, so brew never took ownership. Adopt it rather than
# reinstalling: `brew install --cask --adopt <name>`.

CHECK_OUT=$(brew bundle check --verbose --file="$BREWFILE" 2>&1 | grep -v 'JSON API')

if printf '%s\n' "$CHECK_OUT" | grep -q "dependencies are satisfied"; then
    say ok "Every Brewfile entry is installed and brew-managed"
else
    DRIFT=1
    say warn "Declared in the Brewfile but NOT satisfied:"
    say printf '%s\n' "$CHECK_OUT" | grep '^→' | sed 's/^/    /'
    say echo ""
    say info "  If the app is already in /Applications, adopt it instead of reinstalling:"
    say info "    brew install --cask --adopt <name>     # needs App Management; quit the app first"
fi

say echo ""

# ─── 2. Installed but undeclared ────────────────────────────────────────────
# Parsed from `brew bundle cleanup` (never `--force`) so this report matches
# exactly what enforcement would delete. Only counts things installed ON
# REQUEST — dependencies pulled in by other formulae are correctly ignored,
# which is why a package's dep tree never needs declaring.

CLEANUP_OUT=$(brew bundle cleanup --file="$BREWFILE" 2>/dev/null)

UNDECLARED=$(printf '%s\n' "$CLEANUP_OUT" | awk '
    /^Would `brew cleanup`:/            { emit = 0; next }   # disk cache, not drift
    /^Run `brew bundle cleanup --force/ { emit = 0; next }
    /^Would (uninstall|untap)/          { emit = 1
                                          hdr = $0
                                          sub(/:$/, "", hdr)
                                          sub(/^Would uninstall /, "", hdr)
                                          sub(/^Would untap/, "taps", hdr)
                                          next }
    /^Would remove:/                    { next }
    emit && NF                          { printf "%-22s %s\n", hdr ":", $0 }
')

if [[ -z "$UNDECLARED" ]]; then
    say ok "Nothing installed on request that the Brewfile doesn't declare"
else
    DRIFT=1
    say warn "Installed on this machine but NOT in the Brewfile:"
    say printf '%s\n' "$UNDECLARED" | sed 's/^/    /'
    say echo ""
    say info "  Keep it? Add it to the Brewfile under the right comment group."
    say info "  Don't want it? brew uninstall <name>   (then re-run this script)"
fi

say echo ""

# ─── 3. Orphaned dependencies ───────────────────────────────────────────────
# Not Brewfile drift — these are never declared — but it's the residue left
# when you uninstall a formula and its dependencies stay behind. Reported so
# a try-then-discard week doesn't silently accrete packages.

ORPHANS=$(brew autoremove --dry-run 2>/dev/null | grep -vE '^==>|^$' || true)

if [[ -z "$ORPHANS" ]]; then
    say ok "No orphaned dependencies"
else
    say warn "Orphaned dependencies (no longer required by anything installed):"
    say printf '%s\n' "$ORPHANS" | sed 's/^/    /'
    say info "  Remove with: brew autoremove"
fi

say echo ""

# ─── 4. VS Code extension hazard ────────────────────────────────────────────
# brew bundle ignores the VS Code domain entirely while the Brewfile has zero
# `vscode` lines. Add a single one and `cleanup --force` treats every OTHER
# installed extension as undeclared and uninstalls it. Verified 2026-07-30:
# one `vscode` entry put all 59 other extensions on the uninstall list.

if grep -qE '^[[:space:]]*vscode[[:space:]]' "$BREWFILE"; then
    say warn "Brewfile contains 'vscode' entries — every installed extension must now"
    say warn "be declared, or 'brew bundle cleanup --force' will uninstall the rest."
    say info "  Capture the current set with: brew bundle dump --file=- | grep '^vscode'"
fi

# ─── Summary ────────────────────────────────────────────────────────────────

if [[ "$DRIFT" -eq 0 ]]; then
    say ok "No Brewfile drift"
    exit 0
else
    say err "Brewfile drift detected — see above"
    exit 1
fi
