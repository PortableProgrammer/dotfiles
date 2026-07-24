#!/usr/bin/env bash
set -uo pipefail

# ─── verify-workstation.sh ───────────────────────────────────────────────────
# Read-only post-bootstrap sanity check for FIRST-RUN.md §12. Mechanizes the
# manual check list from that section. Location-independent: works wherever
# this repo is cloned (~/dotfiles, ~/Code/dotfiles, etc.) — derives nothing
# from the clone path.
#
# Usage: ./verify-workstation.sh   (or ~/dotfiles/bin/verify-workstation.sh)
# Exit: 0 iff zero FAILs. WARN/SKIP don't affect exit status.

# ─── Helpers (matches install.sh's idiom) ───────────────────────────────────

info()  { printf '\033[1;34m[info]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[ok]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[warn]\033[0m  %s\n' "$*"; }
err()   { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }
skip()  { printf '\033[1;36m[skip]\033[0m  %s\n' "$*"; }

is_macos() { [[ "$OSTYPE" == darwin* ]]; }
is_linux() { [[ "$OSTYPE" == linux* ]]; }

OK_COUNT=0
WARN_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

record_ok()   { ok "$*";   OK_COUNT=$((OK_COUNT + 1)); }
record_warn() { warn "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
record_skip() { skip "$*"; SKIP_COUNT=$((SKIP_COUNT + 1)); }
record_fail() { err "$*";  FAIL_COUNT=$((FAIL_COUNT + 1)); }

echo ""
info "Workstation verification"
echo ""

# ─── 1. 1Password CLI ───────────────────────────────────────────────────────

if ! command -v op &>/dev/null; then
    record_fail "1Password CLI (op) not found on PATH — FIRST-RUN §6"
elif ! op whoami &>/dev/null; then
    record_fail "1Password CLI found but not signed in (op whoami failed) — FIRST-RUN §6"
else
    record_ok "1Password CLI signed in"
fi

# ─── 2. GitHub CLI ──────────────────────────────────────────────────────────

if ! command -v gh &>/dev/null; then
    record_fail "GitHub CLI (gh) not found on PATH — FIRST-RUN §7"
elif ! gh auth status &>/dev/null; then
    record_fail "GitHub CLI found but not authenticated (gh auth status failed) — FIRST-RUN §7"
else
    record_ok "GitHub CLI authenticated"
fi

# ─── 3. kubectl (conditional on a kubeconfig existing) ─────────────────────

KUBECONFIG_PRESENT=0
if [[ -n "${KUBECONFIG:-}" ]]; then
    KUBECONFIG_PRESENT=1
elif [[ -f "$HOME/.kube/config" ]]; then
    KUBECONFIG_PRESENT=1
fi

if [[ "$KUBECONFIG_PRESENT" -eq 0 ]]; then
    record_skip "kubectl: no kubeconfig found — no project bootstrapped yet — fine"
elif ! command -v kubectl &>/dev/null; then
    record_fail "kubectl not found on PATH but a kubeconfig exists"
elif kubectl get nodes --request-timeout=5s &>/dev/null; then
    record_ok "kubectl reaches cluster (get nodes succeeded)"
else
    record_warn "kubectl found a kubeconfig but couldn't reach/authenticate to the cluster (may be off-network)"
fi

# ─── 4. claude-ops substrate ────────────────────────────────────────────────

CLAUDE_OPS_DIR=""

# Primary: ~/.claude/cross-project-notes is a symlink into the substrate repo;
# its target's parent directory is the repo root. `readlink` (no -f, for BSD
# compat) resolves one level; walk up with dirname rather than `readlink -f`.
CPN_LINK="$HOME/.claude/cross-project-notes"
if [[ -L "$CPN_LINK" ]]; then
    CPN_TARGET=$(readlink "$CPN_LINK")
    # Relative targets resolve against the link's own directory.
    case "$CPN_TARGET" in
        /*) : ;;
        *)  CPN_TARGET="$(dirname "$CPN_LINK")/$CPN_TARGET" ;;
    esac
    CANDIDATE="$(cd "$(dirname "$CPN_TARGET")" 2>/dev/null && pwd)"
    if [[ -n "$CANDIDATE" && -d "$CANDIDATE" ]]; then
        CLAUDE_OPS_DIR="$CANDIDATE"
    fi
fi

# Fallback: conventional clone location.
if [[ -z "$CLAUDE_OPS_DIR" && -d "$HOME/Code/claude-ops" ]]; then
    CLAUDE_OPS_DIR="$HOME/Code/claude-ops"
fi

if [[ -z "$CLAUDE_OPS_DIR" ]]; then
    record_fail "claude-ops checkout not found — substrate writes on this machine will be silently lost — FIRST-RUN §11"
else
    VERIFY_SCRIPT="$CLAUDE_OPS_DIR/verify.sh"
    if [[ -x "$VERIFY_SCRIPT" ]]; then
        if "$VERIFY_SCRIPT" --online; then
            record_ok "claude-ops substrate healthy ($VERIFY_SCRIPT --online)"
        else
            record_fail "claude-ops substrate reported issues ($VERIFY_SCRIPT --online exited non-zero)"
        fi
    else
        record_fail "claude-ops verify.sh missing — substrate not installed or out of date; FIRST-RUN §11"
    fi
fi

# ─── Summary ────────────────────────────────────────────────────────────────

echo ""
info "Summary: ok=$OK_COUNT warn=$WARN_COUNT skip=$SKIP_COUNT fail=$FAIL_COUNT"
echo ""

if [[ "$FAIL_COUNT" -eq 0 ]]; then
    exit 0
else
    exit 1
fi
