# Define 1Password ssh-agent SOCK variable
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# sops on macOS defaults to ~/Library/Application Support/sops/age/keys.txt;
# the age key lives at the XDG path, so point sops there explicitly
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

export PATH="$HOME/.local/bin:$PATH"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
