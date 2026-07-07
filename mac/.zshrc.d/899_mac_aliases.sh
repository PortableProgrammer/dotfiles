# Make ls a little more friendly
alias la='ls -AgGvLhp'

# Make updating homebrew a bit easier
alias brewup='echo -e "Brew Update:\n" && brew update && echo -e "Brew Upgrade:" && brew upgrade --no-ask --greedy --no-quit && echo -e "Brew Autoremove:" && brew autoremove && echo -e "Brew Cleanup:" && brew cleanup'

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
