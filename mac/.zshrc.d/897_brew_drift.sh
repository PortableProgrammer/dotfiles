# ─── Brewfile drift warning ──────────────────────────────────────────────────
# Wraps `brew` to say something the moment an install or uninstall diverges from
# the Brewfile. It WRITES NOTHING — deliberately.
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
