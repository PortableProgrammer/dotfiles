# Make ls a little more friendly
alias la='ls -AgGvLhp'

# Make updating homebrew a bit easier.
#
# No --greedy here. 19 of 20 installed casks declare auto_updates, so --greedy
# was re-downloading apps that update themselves — ~1.2GB in one 2026-08-04 run,
# and it relinks Docker's privileged helpers every time it touches that cask.
# Worse, it never bought what it looked like it was buying: --greedy compares
# brew's Caskroom record, which `--adopt` writes without inspecting the app, so
# an adopted cask is invisible to it forever. `brew-drift.sh` section 3 reads the
# app bundle instead, which is what actually catches that.
#
# `mas upgrade` is here rather than in brewup-deep because nothing else updated
# App Store apps at all — that omission is why a content blocker sat a release
# behind. Xcode is the one to watch: when it has an update, this gets slow.

# Steps that must not sever the chain get their own wrappers: a machine with no
# `mas`, or no repo checkout, should still finish autoremove and cleanup.
_brewup_mas() {
    command -v mas &>/dev/null || return 0
    echo -e "\nApp Store Upgrade:"
    mas upgrade || true
}

# The drift report tails the update deliberately. Shell start is the wrong
# moment — you open a terminal holding a task, and anything printed there
# competes with it. `brewup` is already the housekeeping ritual, so the report
# lands when package state is what you're thinking about anyway.
_brewup_drift() {
    local _script="${BREW_DRIFT_BREWFILE:h}/bin/brew-drift.sh"
    [[ -n "${BREW_DRIFT_BREWFILE:-}" && -x "$_script" ]] || return 0
    echo -e "\nBrewfile Drift:"
    "$_script" || true   # exit 1 means "drift found", not "brewup failed"

    # Stamp that the CHECK ran, which is the only question 898 asks. Whether it
    # found anything is separate — a clean report is still a report.
    [[ -n "${BREW_DRIFT_CACHE:-}" ]] || return 0
    mkdir -p "$BREW_DRIFT_CACHE" 2>/dev/null && touch "$BREW_DRIFT_STAMP" 2>/dev/null
    return 0
}

# The drift report answers "does this machine match the Brewfile?". This answers
# "does the remote have the Brewfile?" — the question that decides what survives
# the machine dying, and the one nothing else asks unless you happen to be cd'd
# into the repo (p10k shows ⇢N there) or ending a Claude session.
#
# It rides this ritual rather than claiming a second shell-start slot. 897's
# staleness nag already guarantees the ritual cannot lapse silently, so unpushed
# work cannot go unnoticed for longer than BREW_DRIFT_MAX_DAYS — which is the
# whole reason a second nag isn't needed.
#
# Unpushed and uncommitted are reported separately and worded differently on
# purpose: a commit is a declaration that something is done, while a dirty tree
# is often just work in progress — or a file that dirtied itself, which is
# exactly what mac/.claude/settings.json does on every settings toggle.
_brewup_unpushed() {
    local _repo="${BREW_DRIFT_BREWFILE:h}"
    [[ -n "${BREW_DRIFT_BREWFILE:-}" ]] || return 0
    command -v git &>/dev/null                        || return 0
    git -C "$_repo" rev-parse --git-dir &>/dev/null   || return 0

    echo -e "\nDotfiles Repo:"

    # No upstream at all — detached HEAD, or a branch never pushed. Worth its
    # own message: those commits are not merely unpushed, they are unreachable
    # from anywhere but this disk.
    if ! git -C "$_repo" rev-parse --abbrev-ref '@{u}' &>/dev/null; then
        printf '\033[1;33m[dotfiles]\033[0m no upstream for the current branch — nothing here is replicated\n'
        printf '\033[1;34m[dotfiles]\033[0m %s\n' "$_repo"
        return 0
    fi

    local _ahead _dirty
    _ahead=$(git -C "$_repo" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
    _dirty=$(git -C "$_repo" status --porcelain 2>/dev/null | grep -c . || true)

    [[ "$_ahead" -gt 0 ]] && \
        printf '\033[1;33m[dotfiles]\033[0m %s commit(s) not pushed — the remote is the only copy that outlives this machine\n' "$_ahead"
    [[ "$_dirty" -gt 0 ]] && \
        printf '\033[1;33m[dotfiles]\033[0m %s file(s) uncommitted\n' "$_dirty"

    if [[ "$_ahead" -eq 0 && "$_dirty" -eq 0 ]]; then
        printf '\033[1;32m[dotfiles]\033[0m clean and pushed\n'
    else
        printf '\033[1;34m[dotfiles]\033[0m %s\n' "$_repo"
    fi
    return 0
}

alias brewup='echo -e "Brew Update:\n" && brew update && echo -e "Brew Upgrade:" && brew upgrade --no-ask --no-quit && _brewup_mas && echo -e "Brew Autoremove:" && brew autoremove && echo -e "Brew Cleanup:" && brew cleanup && _brewup_drift && _brewup_unpushed'

# Force auto-updating casks onto the cask's version. Run when the drift report
# says an app self-updated into a corner, not on a schedule — this replaces app
# bundles under running applications, which is fine when you chose the moment.
alias brewup-deep='echo -e "Greedy Cask Upgrade:" && brew upgrade --cask --no-ask --greedy --no-quit'

# Override all-in-one update
# OMZ runs LAST: `omz update` ends by `exec`-ing a fresh shell when it actually
# pulls a new version (lib/cli.zsh), which replaces this process — anything after
# it in the chain is skipped. Putting it last means brewup always completes first.
alias update='echo -e "macOS Software Update:" && softwareupdate -i -a; brewup; echo -e "\nOMZ Update:" && omz update'

# Can't ever remember ncdu, so alias it up a bit
alias treesize='ncdu --color dark -x'

# IP addresses
alias extip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ip="localip"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# Recursively delete `.DS_Store` files
alias dscleanup="find . -type f -name '*.DS_Store' -ls -delete"

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# macOS has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null || alias md5sum="md5"

# macOS has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitignore | map dirname
alias map="xargs -n1"

# One of @janmoesen’s ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
	alias "${method}"="lwp-request -m '${method}'"
done
