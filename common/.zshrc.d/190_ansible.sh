# Ansible aliases — run as the `automation` identity (KA op-fetched into an
# ephemeral agent; see homelab docs/reviews/ssh-key-audit.md). Gated on the
# homelab repo being present so fleet hosts (which also stow this file but
# never run Ansible) define nothing.
_HOMELAB="$HOME/Code/homelab"
if [ -x "$_HOMELAB/scripts/ansible/with-automation-key.sh" ]; then
  alias ap="$_HOMELAB/scripts/ansible/with-automation-key.sh ansible-playbook --vault-password-file $_HOMELAB/scripts/ansible/vault-pass.sh"
  # Ad-hoc modules, e.g.: aa windows -m ansible.windows.win_ping
  alias aa="$_HOMELAB/scripts/ansible/with-automation-key.sh ansible"
  alias av="ansible-vault --vault-password-file $_HOMELAB/scripts/ansible/vault-pass.sh"
  alias ai='ansible-inventory'
fi

# Ensure nano is the default Ansible editor
export EDITOR=nano
