#!/usr/bin/env bash
set -uo pipefail

# ─── brew-drift.sh ───────────────────────────────────────────────────────────
# Read-only Brewfile drift report. Never installs, uninstalls, or edits
# anything — it only tells you where the machine and the Brewfile disagree.
#
# Drift has THREE directions, and they fail in different ways:
#
#   installed but undeclared  — you `brew install`ed something and never added
#                               it. Loud failure mode: `brew bundle cleanup`
#                               deletes it on some future machine.
#   declared but unsatisfied  — the Brewfile names something brew doesn't
#                               actually manage (commonly an app installed by
#                               hand into /Applications). SILENT failure mode:
#                               everything works here, and the fresh machine
#                               you rebuild in a year quietly lacks it.
#   declared, installed, and  — brew's records say current, the binary on disk
#   stale on disk               is not. SILENT, and invisible to every other
#                               brew command including `upgrade --greedy`.
#
# The second is the dangerous one for rebuilds and the one a `brew bundle dump`
# can never fix — a dump records state, so it would "resolve" the disagreement
# by deleting your intent. That's why this script reports and does not write.
#
# The third is the dangerous one for the machine you are sitting at, because
# every indicator says fine. See section 3 for how that happens.
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

# ─── 3. Declared and installed, but stale on disk ───────────────────────────
# Both checks above trust brew's own bookkeeping, and `--adopt` turns that
# bookkeeping into a claim rather than an observation: adopting writes a
# Caskroom entry named for the cask's CURRENT version without touching the app
# it adopted. `brew outdated` and `brew upgrade --greedy` then compare that
# record against the cask, find them equal, and skip the app forever.
#
# Verified 2026-08-04: Google Chrome sat at 132.0.6834.84, bundle untouched
# since 2025-01, while brew recorded 151.0.7922.72 from a 2026-07-30 adoption.
# Nineteen months of browser patches missed, with every indicator reading OK.
#
# So compare against the bundle's CFBundleShortVersionString and nothing else —
# it is the only value here that is observed rather than asserted.
#
# Direction matters. Disk BEHIND the cask is the adoption failure above —
# real drift, fixed by reinstalling. Disk AHEAD of the cask is the opposite
# and healthy steady state for a self-updating app: the vendor's updater
# ships faster than the cask definition bumps (2026-08-06: Chrome bundle
# .109 minutes after brew poured .76). The reinstall remedy would DOWNGRADE
# that app, so ahead is reported as information, never as drift.

# Casks whose upstream version is structurally incomparable to the bundle's
# (a build id the app never exposes). Empty today; kept so a future false
# positive gets silenced explicitly instead of by loosening the match for all.
STALE_IGNORE=""

# Segment-wise version compare, bash-3.2-safe. Echoes "ahead", "behind", or
# "equal" for $1 relative to $2. Numeric segments compare numerically (so
# .109 > .76); anything non-numeric falls back to string compare, and a tie
# with leftover segments goes to the longer version (1.2.1 > 1.2).
_vercmp() {
    local -a a b
    local i seg_a seg_b
    IFS='.' read -r -a a <<< "$1"
    IFS='.' read -r -a b <<< "$2"
    for (( i = 0; i < ${#a[@]} || i < ${#b[@]}; i++ )); do
        seg_a="${a[i]:-0}"; seg_b="${b[i]:-0}"
        if [[ "$seg_a" =~ ^[0-9]+$ && "$seg_b" =~ ^[0-9]+$ ]]; then
            (( 10#$seg_a > 10#$seg_b )) && { echo ahead;  return; }
            (( 10#$seg_a < 10#$seg_b )) && { echo behind; return; }
        else
            [[ "$seg_a" > "$seg_b" ]] && { echo ahead;  return; }
            [[ "$seg_a" < "$seg_b" ]] && { echo behind; return; }
        fi
    done
    echo equal
}

STALE=""
AHEAD=""
UNVERIFIABLE=""

CASK_LIST=()
while IFS= read -r _c; do [[ -n "$_c" ]] && CASK_LIST+=("$_c"); done < <(brew list --cask 2>/dev/null)

if command -v jq &>/dev/null && [[ ${#CASK_LIST[@]} -gt 0 ]]; then
    # One JSON call for every cask — twenty `brew info` invocations would be
    # too slow to hang off an interactive alias. This is ~0.8s for twenty.
    CASK_JSON=$(brew info --cask --json=v2 "${CASK_LIST[@]}" 2>/dev/null | jq -r '
        .casks[] | [
            .token,
            (.version | split(",")[0]),
            ([ .artifacts[]? | select(type=="object") | .app? // empty
                             | .[]? | select(type=="string") ] | first // "")
        ] | @tsv')

    while IFS=$'\t' read -r token upstream app; do
        [[ -z "$token" ]] && continue
        printf '%s\n' "$STALE_IGNORE" | grep -qx "$token" && continue

        # A cask whose artifact is a pkg, binary, or prefpane has no bundle to
        # read. Named below rather than skipped: a silent skip reads as
        # "checked and fine", which is the failure this section exists to stop.
        if [[ -z "$app" || ! -d "/Applications/$app" ]]; then
            UNVERIFIABLE+="    $token"$'\n'
            continue
        fi

        bundle=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
                 "/Applications/$app/Contents/Info.plist" 2>/dev/null)
        if [[ -z "$bundle" ]]; then
            UNVERIFIABLE+="    $token"$'\n'
            continue
        fi

        # Prefix match both ways absorbs the usual formatting gap, where the
        # cask carries a suffix the bundle omits (royal-tsx 6.4.3.1000 vs
        # 6.4.3). A check that cries wolf gets ignored — same outcome as no
        # check, but with more machinery.
        [[ "$upstream" == "$bundle"* || "$bundle" == "$upstream"* ]] && continue

        mtime=$(stat -f '%Sm' -t '%Y-%m' "/Applications/$app" 2>/dev/null)
        line="$(printf '%-24s cask %-20s disk %-20s app last written %s' \
                "$token" "$upstream" "$bundle" "$mtime")"$'\n'
        if [[ "$(_vercmp "$bundle" "$upstream")" == "ahead" ]]; then
            AHEAD+="$line"
        else
            # "behind" and the unorderable weirdos both land here: anything
            # that can't be proven ahead gets the loud treatment, and a
            # false alarm gets silenced by name via STALE_IGNORE.
            STALE+="$line"
        fi
    done <<< "$CASK_JSON"
fi

if [[ -z "$STALE" ]]; then
    say ok "No readable cask bundle is behind its cask version"
else
    DRIFT=1
    say warn "Installed and declared, but the app on disk is BEHIND the cask:"
    say printf '%s' "$STALE" | sed 's/^/    /'
    say echo ""
    say info "  brew thinks these are current; the bundle says otherwise. Force it:"
    say info "    brew reinstall --cask <name>          # quit the app first"
fi

if [[ -n "$AHEAD" ]]; then
    say info "  App on disk is AHEAD of the cask (self-updated past it) — not drift:"
    say printf '%s' "$AHEAD" | sed 's/^/    /'
    say info "  The cask definition will catch up. Do NOT reinstall — that downgrades."
fi

if [[ -n "$UNVERIFIABLE" ]]; then
    say info "  No .app bundle to read (pkg/binary/prefpane artifact) — not checked:"
    say printf '%s' "$UNVERIFIABLE"
fi

say echo ""

# ─── 4. Mac App Store apps ──────────────────────────────────────────────────
# `brew bundle check` renders "outdated" and "never installed" identically, as
# "needs to be installed or updated" — so an app that is present but months
# behind looks the same as one that was trialled and discarded. Separate them.
# Nothing in the daily routine updated these until 2026-08-04, which is why
# AdGuard for Safari (a content blocker) sat a release behind.

if command -v mas &>/dev/null; then
    MAS_OUT=$(mas outdated 2>/dev/null)
    if [[ -z "$MAS_OUT" ]]; then
        say ok "Mac App Store apps are current"
    else
        DRIFT=1
        say warn "Mac App Store apps with updates available:"
        say printf '%s\n' "$MAS_OUT" | sed 's/^/    /'
        say info "  Update with: mas upgrade"
    fi
    say echo ""
fi

# ─── 5. Orphaned dependencies ───────────────────────────────────────────────
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

# ─── 6. VS Code extension hazard ────────────────────────────────────────────
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
