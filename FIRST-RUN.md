# First-Run Checklist

Steps to do **before** and **after** `./install.sh` on a fresh machine, in order. These are the things `install.sh` deliberately doesn't (or can't) automate — manual interactions, identity bootstrap, OS-level permissions.

If you're the original operator, this is the recovery runbook. If you've forked this repo, these steps will need adjustment for your own accounts and identity provider.

## 0. Pre-install (do this first)

These steps prevent specific failures during `install.sh`. Each one is a 30-second action that saves a re-run cycle.

### 0a. Open the App Store and sign in

The `mas` CLI tool that `install.sh` uses to install App Store apps **cannot sign you in** — Apple removed that capability from `mas` in macOS 10.13+. If the App Store GUI hasn't been signed in at least once on this machine, every `mas` install will fail with `Error Domain=ISErrorDomain Code=-128 "Unknown Error."`

1. Open the App Store app.
2. Click your account icon (bottom-left) and sign in with your Apple ID.
3. Accept any terms / 2FA prompts.
4. **Leave the App Store running** in the background during `install.sh` — being logged in via the GUI is necessary; the CLI uses the GUI's auth session.

### 0b. Trigger Xcode Command Line Tools (CLT)

`install.sh` now triggers the CLT install dialog automatically (via `xcode-select --install`), but you may see this from a different vector first — running `git --version`, `git clone`, or any other developer tool on a vanilla macOS install pops the same dialog. **Click "Install" in the popup and wait for it to complete** before letting `install.sh` proceed past Phase 1. If CLT isn't installed, formulae that need a compiler will fail.

### 0c. (Optional) Install full Xcode from the App Store

Some Brewfile entries — currently just `swiftlint` — require a **full Xcode installation**, not just CLT. Xcode is a ~15 GB install and takes 20+ minutes; only do this if you actively need swiftlint or other Xcode-dependent tooling. If you skip Xcode, expect `swiftlint` to fail during `install.sh`; everything else still installs.

### 0d. Grant Terminal "App Management" permission (macOS 14+)

macOS Sonoma (14) and later require explicit user consent before an app can modify other installed apps. Several Brewfile casks (anything `.pkg`-based that writes to `/Applications`) trip this gate during install — you'll see a `chown` or permission error mid-script.

**Pre-approve before running `install.sh`:**

1. System Settings → Privacy & Security → App Management.
2. Toggle on whichever terminal you're running `install.sh` from (Terminal, iTerm2, Ghostty, Warp, etc.).
3. **Critical**: if macOS prompts to restart the terminal app for the change to take effect, accept. Once the terminal restarts, the sudo cache is cleared and any in-flight `install.sh` is gone. **Granting this permission mid-install means re-running the script from the beginning** — better to grant it before starting.

### 0e. Verify the App Store can actually transact (bare-metal only)

Just being signed in isn't enough — the App Store also needs to be able to *complete a download*. Verify by installing one free app manually from the GUI **before** running `install.sh`. If the manual install fails with `Unknown Error` (`ISErrorDomain Code=-128`), the problem is at the Apple-ID / device-trust layer.

Possible causes:
- New device requires approval from an already-signed-in device (check your phone or another Mac for a pending verification prompt).
- Apple ID security review (sometimes triggered for new-device sign-in, can take up to 24h).
- Payment method missing or rejected — Apple sometimes requires a valid payment method on file even for free apps when the device is brand-new.

**Virtualized macOS — different story:** per [Apple Support article 120468](https://support.apple.com/en-us/120468), iCloud services including the Mac App Store are **not available on virtualized macOS**, even with a valid Apple ID and a verified trusted device. This is a platform-level restriction, not a configuration problem. `install.sh` detects virtualized macOS (`sysctl -n hw.model` matching `VirtualMac*`, `VMware*`, `Parallels*`, or `QEMU`) and **automatically skips the `mas` block** in that case — no action needed. The App Store apps will need to be installed on a bare-metal target.

## What to expect during `install.sh` itself

`install.sh` requests your sudo password once at start and keeps the sudo timestamp alive for the duration of the run. **You may still see additional password prompts** for certain casks (`docker-desktop`, `wireshark`, `microsoft-office`, `logi-options+`, and similar `.pkg`-based installers). These prompts come from macOS Authorization Services — they bypass the `sudo` cache and ask for your password directly. This is expected, not a bug.

If `brew bundle` reports failures at the end of Phase 1, the script will now continue to subsequent phases rather than aborting. After the script finishes, address the failed items and re-run `./install.sh` — `brew bundle` is idempotent, so already-installed entries are skipped.

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
