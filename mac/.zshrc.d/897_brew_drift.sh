# ─── Brewfile drift warning ──────────────────────────────────────────────────
# Wraps `brew` to say something the moment an install or uninstall diverges from
# the Brewfile. It WRITES NOTHING — deliberately.
#
# Why warn-only rather than auto-editing the Brewfile: a wrapper that appends on
# install and deletes on uninstall turns the Brewfile into a mirror of machine
# state, and the Brewfile's whole value is that it records *intent*. Auto-delete
# would strip the line and the comment explaining why the entry existed; a week
# of trying packages you later discard would produce paired add/remove commits
# with zero net change. A warning you ignore costs nothing and leaves no artifact.
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

    local _pkg _drifted=0
    for _pkg in "${_pkgs[@]}"; do
        if [[ "$_expect_declared" -eq 1 ]]; then
            _brew_drift_declared "$_kind" "$_pkg" && continue
            printf '\033[1;33m[brewfile]\033[0m %s is installed but NOT declared — it will be lost on the next machine.\n' "$_pkg"
        else
            _brew_drift_declared "$_kind" "$_pkg" || continue
            printf '\033[1;33m[brewfile]\033[0m %s is removed but STILL declared — the next bootstrap will reinstall it.\n' "$_pkg"
        fi
        _drifted=1
    done

    [[ "$_drifted" -eq 1 ]] && printf '\033[1;34m[brewfile]\033[0m %s\n' "$BREW_DRIFT_BREWFILE"
    return 0
}

brew() {
    command brew "$@"
    local _status=$?
    # Only comment on a successful mutation, and never alter brew's exit code.
    [[ $_status -eq 0 ]] && _brew_drift_check "$@"
    return $_status
}
