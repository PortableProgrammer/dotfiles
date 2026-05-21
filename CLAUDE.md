# Dotfiles Project

## Repo Structure

This repo uses [GNU Stow](https://www.gnu.org/software/stow/) to symlink dotfiles into `$HOME`. Each top-level directory that represents a stow package mirrors the home directory layout.

- `common/` — Stow package for all platforms (Linux + macOS)
- `mac/` — Stow package for macOS only (overlays on top of common)
- `resources/` — Non-stowed assets (fonts, Terminal.app theme, iStat Menus settings backup)
- `scripts/` — Standalone scripts (Dock layout via `dockutil`, macOS system defaults)
- `Brewfile` — Declarative Homebrew package list (macOS): formulae, casks, and Mac App Store apps; installed via `brew bundle`

## Commands

```bash
# Full bootstrap (installs deps, stows dotfiles, sets up shell)
./install.sh

# Stow individual packages
stow -d ~/dotfiles -t ~ common
stow -d ~/dotfiles -t ~ mac

# Unstow a package
stow -D -d ~/dotfiles -t ~ common

# Dry run
stow -n -v -d ~/dotfiles -t ~ common
```

## File Loading Order

1. `.zshrc` sets `POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true`
2. `.zshrc` aliases `fdfind` to `fd` (on macOS, `fd-find` installs as `fd` not `fdfind`)
3. `.zshrc` uses `fdfind` to discover all `~/.zshrc.d/*.sh` files
4. Scripts are sourced in sorted order (numeric prefix controls order)
5. `900_p10k.sh` loads `~/.p10k.zsh` as the final step

## Key Patterns

- **Numbered modules in `.zshrc.d/`**: `0xx` = early init, `1xx` = framework/aliases, `2xx` = bindings, `8xx` = platform-specific (mac), `9xx` = final (prompt)
- **Common vs mac separation**: Common package has cross-platform files (shell config, nano, screen); mac package adds macOS-specific files (`.gitconfig` for identity/signing, `.ssh/config` for 1Password agent, `.claude/` for Claude Code, `.zshrc.d/` mac scripts)
- **SSH signing key**: On macOS, `install.sh` fetches the SSH signing public key from GitHub's `/users/{username}/ssh_signing_keys` API and writes it to `~/.ssh/id_ed25519.pub` for git commit signing. The key is not stored in the repo — GitHub is the single source of truth.
- **Idempotent installer**: `install.sh` checks for existing installations before acting — safe to re-run
- **Single-source macOS setup**: `install.sh` is the sole entry point for macOS — Homebrew packages (via `Brewfile`), shell framework, SSH signing key, dotfiles, fonts, Terminal theme, Dock layout, and system defaults are all managed here (not in Ansible)
- **Brewfile for packages**: Add/remove Homebrew formulae, casks, and Mac App Store apps in `Brewfile`, not in `install.sh`. Mac App Store apps use `mas` (installed via Brewfile) and require being signed in with an Apple ID that has previously obtained the app.
- **Dock layout**: `scripts/dock.sh` manages Dock contents via `dockutil`. Run standalone or through `install.sh` (which prompts first). Edit `dock.sh` to change which apps appear in the Dock.

## Ansible Integration

The homelab repo's Ansible roles clone this repo and run `stow` to deploy dotfiles on managed hosts. The repo URL and branch are configured via the `common_dotfiles_repo`, `common_dotfiles_version`, and `common_dotfiles_dest` variables in the homelab's Ansible role defaults.

## Ideating notebook

Out-of-repo ideating-window output lives at:
`~/.claude/projects/-Users-nwarner-Code-dotfiles/ideating/`

Half-baked ideas, speculative architecture proposals, and tooling-gap notes from sessions where the operator was unavailable and an ideating window was sanctioned per the global rule. The notebook compounds; ideas that don't pan out on their own often seed ones that do, so old entries are worth glancing at, not just the latest.

Most recent entry: `2026-05-18.md` — public-flip resolution + deferred items (Brewfile drift, fresh-install validation, ansible vault templating decision, prompt-segment greenfield lesson, pointers to operator-triage notes). Read the latest before starting open-ended work.
