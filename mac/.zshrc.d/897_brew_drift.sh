# ─── Brewfile drift awareness ────────────────────────────────────────────────
# Two jobs, both about noticing when the machine and the Brewfile disagree:
#
#   1. A `brew` wrapper that speaks up the moment an interactive install or
#      uninstall diverges from the Brewfile.
#   2. A shell-start nag, fired only when the full drift check is overdue.
#
# Neither one ever writes the Brewfile — that is the deliberate part, and the
# rest of this header is why. (Part 2 does write a timestamp under
# $BREW_DRIFT_CACHE; that is bookkeeping about when a check ran, not intent.)
#
# Why warn-only rather than auto-editing the Brewfile: the Brewfile records
# *intent*, and anything derived from machine state can only record *state*.
#
# The argument this comment used to make — that trial installs would produce
# paired add/remove commits with zero net change — does not survive scrutiny, so
# don't lean on it: an add and a remove before any commit returns the file to
# unmodified, and commits are free anyway. The reasons that do hold:
#
#   1. Auto-add alone leaves a trial you abandoned declared-but-unsatisfied.
#      That is the *silent* drift direction (11 of 16 findings on 2026-07-30),
#      so the cheap half of the feature makes the worse half of the problem.
#   2. Getting the self-cancelling property requires auto-delete too, and a
#      deleted line takes its inline note with it. Only 6 of 62 declarations
#      carry one, but they are the ones that stop a repeat mistake — see the
#      onedrive conflict warning on microsoft-office.
#   3. State-derived writes cannot see entries that describe an *absent*
#      package (the claude-code and powershell blocks). A regenerating writer
#      deletes those unconditionally; it has no input that says they exist.
#
# None of that is unsolvable — a line-editing writer that comments a line out
# instead of deleting it when the line carries a note would answer (2) and (3).
# It is unbuilt because a printf already buys the outcome for no moving parts.
#
# What this buys over bin/brew-drift.sh: latency. The drift script is stateless
# and correct, but only runs when invoked — `libsmi` sat undeclared for 79 days
# before anyone looked. This closes that to zero for interactive installs.
#
# What it does NOT buy: coverage. A zsh function only sees what you type in an
# interactive shell. Installs from install.sh, Ansible, or any script bypass it
# entirely, so the periodic drift check remains the actual safety net.
#
# Silence for a session with: BREW_DRIFT_WARN=0

# Resolve the Brewfile once, at shell start. Repo location varies by machine.
if [[ -z "${BREW_DRIFT_BREWFILE:-}" ]]; then
    for _bd_candidate in "$HOME/Code/dotfiles/Brewfile" "$HOME/dotfiles/Brewfile"; do
        if [[ -f "$_bd_candidate" ]]; then
            BREW_DRIFT_BREWFILE="$_bd_candidate"
            break
        fi
    done
    unset _bd_candidate
fi

# Shared drift state, defined here because this is the module that owns drift
# configuration — but written by neither this file nor this wrapper, which
# still touch nothing. 899's `brewup` stamps last-run after the report; 898
# stamps last-nag when it complains about last-run being old.
BREW_DRIFT_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/brew-drift"
BREW_DRIFT_STAMP="$BREW_DRIFT_CACHE/last-run"
BREW_DRIFT_NAG_STAMP="$BREW_DRIFT_CACHE/last-nag"

# Is <name> declared in the Brewfile as <kind>? Tolerates a tap prefix, so
# `brew install flux` matches a declared `brew "fluxcd/tap/flux"`.
_brew_drift_declared() {
    local _kind="$1" _name="$2" _esc
    # Escape the regex metacharacters that appear in real package names —
    # logi-options+ and visual-studio-code@insiders both exist.
    _esc="${_name//\\/\\\\}"
    _esc="${_esc//+/\\+}"
    _esc="${_esc//./\\.}"

    case "$_kind" in
        tap) grep -qE "^[[:space:]]*tap[[:space:]]+\"${_esc}\"" "$BREW_DRIFT_BREWFILE" ;;
        *)   grep -qE "^[[:space:]]*(brew|cask)[[:space:]]+\"([^\"]*/)?${_esc}\"" "$BREW_DRIFT_BREWFILE" ;;
    esac
}

# Warning logic, split from the wrapper so it can be exercised without actually
# invoking brew. Takes the raw argv of a brew invocation.
_brew_drift_check() {
    [[ "${BREW_DRIFT_WARN:-1}" != "0" ]]            || return 0
    [[ -f "${BREW_DRIFT_BREWFILE:-/nonexistent}" ]] || return 0

    # First non-flag arg is the subcommand; the rest are package names.
    local _sub="" _arg
    local -a _pkgs
    for _arg in "$@"; do
        [[ "$_arg" == -* ]] && continue
        if [[ -z "$_sub" ]]; then _sub="$_arg"; else _pkgs+=("$_arg"); fi
    done
    [[ ${#_pkgs[@]} -gt 0 ]] || return 0

    # expect_declared: after this subcommand, SHOULD the name be in the Brewfile?
    local _kind="pkg" _expect_declared
    case "$_sub" in
        install|reinstall) _expect_declared=1 ;;
        uninstall|remove|rm) _expect_declared=0 ;;
        tap)   _kind="tap"; _expect_declared=1 ;;
        untap) _kind="tap"; _expect_declared=0 ;;
        *) return 0 ;;
    esac

    local _pkg _drifted=0 _line
    for _pkg in "${_pkgs[@]}"; do
        if [[ "$_expect_declared" -eq 1 ]]; then
            _brew_drift_declared "$_kind" "$_pkg" && continue
            # Name the exact line to paste rather than the problem alone. A cask
            # that just installed has a Caskroom directory and a formula doesn't,
            # which settles the keyword without asking brew a second question.
            if [[ "$_kind" == tap ]]; then
                _line="tap \"$_pkg\""
            elif [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/Caskroom/$_pkg" ]]; then
                _line="cask \"$_pkg\""
            else
                _line="brew \"$_pkg\""
            fi
            printf '\033[1;33m[brewfile]\033[0m %s installed but not declared — add: %s\n' "$_pkg" "$_line"
        else
            _brew_drift_declared "$_kind" "$_pkg" || continue
            printf '\033[1;33m[brewfile]\033[0m %s removed but still declared — drop its line, or the next bootstrap reinstalls it.\n' "$_pkg"
        fi
        _drifted=1
    done

    # One trailer, not one per package: the path to edit, plus explicit standing
    # permission to ignore the whole thing. Undeclared is a valid state for a
    # package you are still deciding about — see the header.
    if [[ "$_drifted" -eq 1 ]]; then
        local _hint="a trial install needs no entry"
        [[ "$_expect_declared" -eq 0 ]] && _hint="leave it declared if you mean to reinstall"
        printf '\033[1;34m[brewfile]\033[0m %s — nothing was written; %s\n' "$BREW_DRIFT_BREWFILE" "$_hint"
    fi
    return 0
}

brew() {
    command brew "$@"
    local _status=$?
    # Only comment on a successful mutation, and never alter brew's exit code.
    # The function-exists guard matters for shells that inherit this wrapper
    # without its helpers — snapshot-based shells (Claude Code's Bash tool) and
    # partial profile sourcing both do this. A warning must never be able to
    # print an error over a brew command that actually succeeded.
    [[ $_status -eq 0 ]] && (( $+functions[_brew_drift_check] )) && _brew_drift_check "$@"
    return $_status
}

# ─── Part 2: staleness nag ───────────────────────────────────────────────────
# The full report (bin/brew-drift.sh) rides `brewup` in 899, because a terminal
# gets opened holding a task and anything printed at shell start competes with
# it. That placement has exactly one blind spot: it cannot tell you the ritual
# itself has lapsed. A check nobody runs reports nothing, which reads the same
# as a clean machine — the trap that let an adopted Google Chrome sit nineteen
# months stale behind a brew record claiming it was current.
#
# So this is the only thing that earns a shell-start slot: not findings, just
# "the thing that finds things hasn't run." Silent until overdue, and at most
# once a day, because a line seen fifty times a day stops being read.
#
# It also stands in for a launchd agent. A weekly LaunchAgent would need this
# same freshness guard anyway — agents are user-disablable from Login Items &
# Extensions, and a disabled one is silent — so the guard was built and the
# agent was not.
#
# Prints during zsh init, which is safe only because the p10k instant-prompt
# preamble is NOT in .zshrc (verified 2026-08-04). If that ever changes, move
# this to a precmd hook or instant prompt will flag it as console output.
#
# Silence with BREW_DRIFT_WARN=0; retune with BREW_DRIFT_MAX_DAYS=<n>.

BREW_DRIFT_MAX_DAYS="${BREW_DRIFT_MAX_DAYS:-21}"

# Compares calendar dates rather than elapsed hours, so the nag resets
# overnight instead of at an arbitrary offset from whenever it last fired.
_brew_drift_nagged_today() {
    [[ -f "${BREW_DRIFT_NAG_STAMP:-/nonexistent}" ]] || return 1
    [[ "$(date -r "$BREW_DRIFT_NAG_STAMP" +%F 2>/dev/null)" == "$(date +%F)" ]]
}

_brew_drift_staleness() {
    [[ "${BREW_DRIFT_WARN:-1}" != "0" ]] || return 0
    [[ -n "${BREW_DRIFT_BREWFILE:-}" ]]  || return 0   # no checkout, nothing to nag about
    [[ -n "${BREW_DRIFT_STAMP:-}" ]]     || return 0
    _brew_drift_nagged_today && return 0

    local _msg
    if [[ ! -f "$BREW_DRIFT_STAMP" ]]; then
        _msg="the Brewfile drift check has never run here"
    else
        local _days=$(( ( $(date +%s) - $(stat -f %m "$BREW_DRIFT_STAMP" 2>/dev/null || echo 0) ) / 86400 ))
        [[ "$_days" -lt "$BREW_DRIFT_MAX_DAYS" ]] && return 0
        _msg="the Brewfile drift check last ran ${_days} days ago"
    fi

    printf '\033[1;33m[brewfile]\033[0m %s — run \033[1mbrewup\033[0m\n' "$_msg"

    mkdir -p "$BREW_DRIFT_CACHE" 2>/dev/null && touch "$BREW_DRIFT_NAG_STAMP" 2>/dev/null
    return 0
}

_brew_drift_staleness
