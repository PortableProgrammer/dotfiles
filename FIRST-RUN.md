# First-Run Checklist

Steps to do **after** `./install.sh` completes on a fresh machine, in order. These are the things `install.sh` deliberately doesn't (or can't) automate — manual interactions, identity bootstrap, OS-level permissions.

If you're the original operator, this is the recovery runbook. If you've forked this repo, these steps will need adjustment for your own accounts and identity provider.

## 1. Sign in to 1Password

Required first — almost everything downstream pulls credentials from 1Password.

1. Launch the 1Password desktop app (installed by `install.sh` via Brewfile).
2. Enter your **account URL**, **email**, **Secret Key**, and **Master Password** — all four come from the printed Emergency Kit.
3. Approve the 2FA prompt from your authenticator.
4. **Enable the SSH agent**: 1Password → Settings → Developer → check *Use the SSH agent*.
5. **Enable biometric unlock**: 1Password → Settings → Security → enable Touch ID (macOS) or your equivalent.
6. Open a fresh terminal and verify:

    ```bash
    op whoami         # should print your account info
    ssh-add -L        # should list keys served by the 1Password agent
    ```

If `op whoami` fails, run `op signin` and follow the prompt.

## 2. Authenticate GitHub CLI

```bash
gh auth login
# Choose: GitHub.com → HTTPS → Authenticate via browser
```

Verify:

```bash
gh auth status
```

Once `gh` is authenticated and the 1Password SSH agent is serving your key, all subsequent `git clone` commands work over either HTTPS or SSH.

## 3. Start your container runtime

`install.sh` installs the runtime via Brewfile but doesn't launch or license it.

**Docker Desktop:**

1. Launch Docker Desktop from `/Applications`.
2. Accept the license terms.
3. Sign in if your usage tier requires it.
4. Verify: `docker ps` runs without error.

**Colima** (alternative, no GUI):

```bash
colima start
docker ps
```

Pick one and stick with it — projects with devcontainers don't care which runs, but mixing both wastes resources.

## 4. macOS system permissions (macOS only)

These can only be granted by hand via System Settings. Some apps will prompt on first use; others have to be granted proactively.

**System Settings → Privacy & Security:**

- **Full Disk Access**: enable for Terminal (or iTerm2 / Ghostty / whatever you use), VS Code, and any tool that needs to read protected directories. Without this, some `git` operations and most backup tools fail silently.
- **Accessibility**: grant to any window-management or automation tool you've installed (Rectangle, Raycast, etc.).
- **Developer Tools**: enable for your terminal, so it can run unsigned binaries Homebrew installs.

**System Settings → Touch ID & Password:**

- Enroll Touch ID.
- (Optional) Enable Touch ID for sudo: `sudo sh -c 'cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local && sed -i "" "s/^#auth/auth/" /etc/pam.d/sudo_local'`

**Browser:**

- Install the 1Password browser extension when prompted on first launch of your browser. Sign in.

## 5. Network access

If you operate services that live behind a VPN, get on the VPN before continuing. The mechanism depends on your setup (UniFi Teleport, WireGuard, Tailscale, corporate VPN, etc.) — install/configure per your project's documentation, not this repo.

Verify by reaching a known internal hostname:

```bash
ping <some-internal-host>
```

If that fails, downstream project bootstrap (kubectl, internal git, etc.) will also fail.

## 6. Per-project bootstrap

`install.sh` and the steps above give you a working **operator workstation** — shell, editor, package manager, identity, network. They don't set up any specific project.

For each project you operate, follow its own bootstrap doc (typically `docs/operator-bootstrap.md` or similar in the project repo). Project bootstrap is where you'll:

- Clone the project repo
- Materialize the irreducible filesystem secrets (e.g. SOPS age keys, kubeconfig, Ansible vault password) from 1Password via `op read`
- Install project-specific tools not in the global Brewfile
- Run a project-specific verification script

If you're the operator setting up the first project on a new machine: this is where you go next.

## 7. Verification

A `bin/verify-workstation.sh` should exit cleanly. Run it now to catch anything the above missed:

```bash
~/Code/dotfiles/bin/verify-workstation.sh
```

> [!NOTE]
> If that script doesn't exist yet, it's on the backlog — see the dotfiles ideating notebook.

## When this doc lies

This checklist will rot. macOS reshuffles System Settings paths every couple of releases; 1Password ships UI changes; Brewfile gains and loses entries. When you find an inaccuracy:

1. Fix it in this file in the same session, while it's fresh.
2. Commit with a `docs(FIRST-RUN):` prefix so the drift trail is visible.
3. If you found the inaccuracy during a fresh-machine bootstrap, also bump `install.sh` if the gap could be automated.

The point of the doc is to be true at any moment, not to be retroactively reconstructed.
