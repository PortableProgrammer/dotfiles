# First-Run Checklist

Linear runbook for a fresh macOS install. Walk from the top.

1. **Pre-install gates** (steps 1–4): things `install.sh` can't do.
2. **Run `./install.sh`** (step 5).
3. **Post-install** (steps 6–12): identity, permissions, projects.

---

## Pre-install gates

### 1. Sign in to the App Store and verify a download works

Required for the `mas` block of the Brewfile. `mas` cannot sign in or prompt — it uses the App Store GUI's session.

1. Open the App Store, click your account icon (bottom-left), sign in.
2. **Install one free app manually** (e.g. Apple Configurator 2). If this fails, `mas` will fail the same way.
3. Leave App Store running during `install.sh`.

If the manual install errors with `ISErrorDomain Code=-128 "Unknown Error"`: check your phone for a "new device" approval, allow up to 24h for Apple ID security review, or confirm a payment method is on file.

> [!IMPORTANT]
> **Virtualized macOS** — skip this step. Per [Apple Support 120468](https://support.apple.com/en-us/120468), the App Store is not available in VMs. `install.sh` detects VMs (`sysctl -n hw.model` matching `VirtualMac*`/`VMware*`/`Parallels*`/`QEMU`) and skips the `mas` block automatically.

### 2. Trigger Xcode Command Line Tools

`install.sh` runs `xcode-select --install` automatically. Click **Install** in the popup and wait for it to finish before proceeding past Phase 1.

> [!TIP]
> On a VM, the CLT dialog can hide behind a full-screen terminal. Shrink the terminal if you don't see it.

### 3. (Optional) Install full Xcode

`swiftlint` requires full Xcode (~15 GB, App Store). Skip unless you need it; the rest of `install.sh` runs fine without.

### 4. Grant Terminal "App Management" and "Full Disk Access"

System Settings → Privacy & Security → toggle your terminal on both:

- **App Management** — required for `.pkg` casks (docker-desktop, microsoft-office, etc.) to write to `/Applications`.
- **Full Disk Access** — required for `scripts/macos-defaults.sh` to write Safari preferences (sandboxed app).

If macOS prompts to restart the terminal, accept. **Granting these mid-install means re-running the script from scratch**, so do it now.

---

## 5. Run `./install.sh`

```bash
cd ~/dotfiles
./install.sh
```

Expect multiple password prompts during `.pkg` cask installs (these bypass sudo cache by design). `brew bundle` partial failures are tolerated — the script continues to Phases 2-5. Re-run after fixing failures; every phase is idempotent.

---

## Post-install

### 6. 1Password

1. Launch the 1Password app, sign in via Emergency Kit (account URL, email, Secret Key, Master Password).
2. Settings → Developer → enable **Use the SSH agent**.
3. Settings → Security → enable Touch ID unlock.
4. Verify:

    ```bash
    op whoami
    ssh-add -L
    ```

### 7. GitHub CLI

```bash
gh auth login        # GitHub.com → HTTPS → browser
gh auth status
```

### 8. Container runtime

Launch Docker Desktop from `/Applications`, accept the license, sign in if required. Verify with `docker ps`.

### 9. macOS system permissions

System Settings → Privacy & Security:

- **Full Disk Access**: enable for VS Code and any backup/sync tools (Terminal was already done in step 4).
- **Accessibility**: grant to window-management / automation tools you've installed.
- **Developer Tools**: enable for your terminal.

Touch ID & Password: enroll Touch ID. (`install.sh` already configured PAM to use it for sudo once enrolled.)

Browser: install the 1Password browser extension on first launch.

### 10. Network access

If your services are behind a VPN (UniFi Teleport / WireGuard / Tailscale / etc.), connect now. Verify:

```bash
ping <some-internal-host>
```

### 11. Per-project bootstrap

Bootstrap `claude-ops` first. It's the AI-session substrate — memory, ideating notes, cross-project hand-offs — that every Claude Code session on this machine reads and writes; skip it and substrate writes are silently lost until it's in place. Requires the 1Password SSH agent (step 6) and `gh` auth (step 7).

```bash
gh repo clone PortableProgrammer/claude-ops ~/Code/claude-ops
cd ~/Code/claude-ops
cp host-mapping.example.yaml host-mapping.yaml
$EDITOR host-mapping.yaml
./install.sh --dry-run
./install.sh
```

> [!NOTE]
> `dotfiles-app-state` is intentionally absent here — it doesn't exist yet ([PortableProgrammer/claude-ops#21](https://github.com/PortableProgrammer/claude-ops/issues/21)).

For every other project, follow its own `docs/operator-bootstrap.md` (or equivalent). Project bootstrap typically pulls SOPS age keys, kubeconfig, and Ansible vault passwords from 1Password via `op read`.

### 12. Verification

```bash
~/dotfiles/bin/verify-workstation.sh
```

Checks (read-only): 1Password CLI signed in, GitHub CLI authenticated, `kubectl get nodes` if a kubeconfig exists (skipped otherwise), and the claude-ops substrate — including its own `verify.sh --online` — is present and healthy.

> [!TIP]
> Mid-bootstrap, before the script's prerequisites are in place, check manually: new terminal shows Smyck + glyphs, `op whoami`, `gh auth status`, `kubectl get nodes` (if a project's been bootstrapped).

---

*Found a gap on a fresh-machine bootstrap? Fix it here in the same session and commit with a `docs(FIRST-RUN):` prefix. If the gap could be automated, also bump `install.sh`.*
