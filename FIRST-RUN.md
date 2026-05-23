# First-Run Checklist

Linear runbook for a fresh machine. Walk it from the top. The flow is:

1. **Pre-install gates** (steps 1–4): prevent specific failures by handling things `install.sh` can't.
2. **Run `./install.sh`** (step 5): automated bootstrap.
3. **Post-install identity + setup** (steps 6–11): manual interactions the installer deliberately doesn't (or can't) automate.

If you're the original operator, this is the recovery runbook. If you've forked this repo, the post-install steps will need adjustment for your own accounts.

---

## Pre-install gates

These steps prevent specific failures during `install.sh`. Each one is a 30-second action that saves a re-run cycle.

### 1. Verify the App Store works (bare-metal only)

The `mas` CLI tool that `install.sh` uses to install App Store apps cannot sign you in or pop dialogs — it relies entirely on the App Store GUI's auth session. So **sign in *and* verify a real download works** before you trust `mas`:

1. Open the App Store app.
2. Click your account icon (bottom-left) and sign in with your Apple ID. Accept any terms / 2FA prompts.
3. **Install one free app manually** (any free thing — Apple Configurator 2, GarageBand, anything that doesn't cost money). If this succeeds, `mas` will work too.
4. **Leave the App Store running** during `install.sh`.

If the manual install fails with `Unknown Error` (`ISErrorDomain Code=-128`):
- New device requires approval from an already-signed-in device (check your phone or another Mac for a pending verification prompt).
- Apple ID security review (sometimes triggered for new-device sign-in, can take up to 24h).
- Payment method missing or rejected — Apple sometimes requires a valid payment method on file even for free apps when the device is brand-new.

**Virtualized macOS — skip this step:** per [Apple Support article 120468](https://support.apple.com/en-us/120468), iCloud services including the Mac App Store are **not available on virtualized macOS**, even with a valid Apple ID and a verified trusted device. This is a platform-level restriction, not a configuration problem. `install.sh` detects virtualized macOS (`sysctl -n hw.model` matching `VirtualMac*`, `VMware*`, `Parallels*`, or `QEMU`) and **automatically skips the `mas` block**. The App Store apps will need to be installed on a bare-metal target.

### 2. Trigger Xcode Command Line Tools (CLT)

`install.sh` triggers the CLT install dialog automatically (via `xcode-select --install`), but you may see this from a different vector first — running `git --version`, `git clone`, or any other developer tool on a vanilla macOS install pops the same dialog. **Click "Install" in the popup and wait for it to complete** before letting `install.sh` proceed past Phase 1. If CLT isn't installed, formulae that need a compiler will fail.

> [!TIP]
> On a VM, the CLT install dialog can hide behind a full-screen terminal — `Cmd+Tab` / Mission Control on the VM may not surface it. If the dialog seems missing, shrink the terminal window to find it.

### 3. (Optional) Install full Xcode from the App Store

Some Brewfile entries — currently just `swiftlint` — require a **full Xcode installation**, not just CLT. Xcode is a ~15 GB install and takes 20+ minutes; only do this if you actively need swiftlint or other Xcode-dependent tooling. If you skip Xcode, expect `swiftlint` to fail during `install.sh`; everything else still installs.

### 4. Grant Terminal "App Management" permission (macOS 14+)

macOS Sonoma (14) and later require explicit user consent before an app can modify other installed apps. Several Brewfile casks (anything `.pkg`-based that writes to `/Applications`) trip this gate during install — you'll see a `chown` or permission error mid-script.

**Pre-approve before running `install.sh`:**

1. System Settings → Privacy & Security → App Management.
2. Toggle on whichever terminal you're running `install.sh` from (Terminal, iTerm2, Ghostty, Warp, etc.).
3. **Critical**: if macOS prompts to restart the terminal app for the change to take effect, accept. Granting this permission mid-install means re-running the script from the beginning (the sudo cache is cleared with the terminal restart).

---

## 5. Run `./install.sh`

```bash
cd ~/dotfiles
./install.sh
```

### What to expect during the run

- **One sudo prompt at the start** for the script's own sudo keep-alive. After that, sudo stays cached.
- **Additional password prompts** for certain casks (`docker-desktop`, `wireshark`, `microsoft-office`, `logi-options+`, and similar `.pkg`-based installers). These come from macOS Authorization Services — they bypass the `sudo` cache and ask for your password directly. Not a bug.
- **Permission popups** for some apps that need additional macOS privileges during install (e.g. Logi Options+ requesting Bluetooth and Input Monitoring). You can interact with these while the script continues in the background.
- **`brew bundle` partial failure is tolerated** — the script continues to subsequent phases. After the script finishes, address the failed items and re-run `./install.sh` to retry. `brew bundle` is idempotent; already-installed entries are skipped.

If the script aborts mid-way (e.g. a stow conflict, network drop), fix the cause and re-run — every phase is idempotent.

---

## Post-install: identity, permissions, and per-project setup

After `install.sh` completes, walk these in order.

## 6. Sign in to 1Password

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

## 7. Authenticate GitHub CLI

```bash
gh auth login
# Choose: GitHub.com → HTTPS → Authenticate via browser
```

Verify:

```bash
gh auth status
```

Once `gh` is authenticated and the 1Password SSH agent is serving your key, all subsequent `git clone` commands work over either HTTPS or SSH.

## 8. Start your container runtime

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

## 9. macOS system permissions (macOS only)

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

## 10. Network access

If you operate services that live behind a VPN, get on the VPN before continuing. The mechanism depends on your setup (UniFi Teleport, WireGuard, Tailscale, corporate VPN, etc.) — install/configure per your project's documentation, not this repo.

Verify by reaching a known internal hostname:

```bash
ping <some-internal-host>
```

If that fails, downstream project bootstrap (kubectl, internal git, etc.) will also fail.

## 11. Per-project bootstrap

`install.sh` and the steps above give you a working **operator workstation** — shell, editor, package manager, identity, network. They don't set up any specific project.

For each project you operate, follow its own bootstrap doc (typically `docs/operator-bootstrap.md` or similar in the project repo). Project bootstrap is where you'll:

- Clone the project repo
- Materialize the irreducible filesystem secrets (e.g. SOPS age keys, kubeconfig, Ansible vault password) from 1Password via `op read`
- Install project-specific tools not in the global Brewfile
- Run a project-specific verification script

If you're the operator setting up the first project on a new machine: this is where you go next.

## 12. Verification

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
