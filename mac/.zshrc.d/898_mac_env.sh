# Define 1Password ssh-agent SOCK variable
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

export PATH="$HOME/.local/bin:$PATH"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/nwarner/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
