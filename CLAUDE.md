# Dotfiles Project

## Repo Structure

This repo uses [GNU Stow](https://www.gnu.org/software/stow/) to symlink dotfiles into `$HOME`. Each top-level directory that represents a stow package mirrors the home directory layout.

- `common/` — Stow package for all platforms (Linux + macOS)
- `mac/` — Stow package for macOS only (overlays on top of common)
- `resources/` — Non-stowed assets (fonts, Terminal.app theme)
- `scripts/` — Standalone scripts (macOS system defaults)
- `Brewfile` — Declarative Homebrew package list (macOS); installed via `brew bundle`

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
- **Common vs mac separation**: Common aliases (e.g. `la`, `update`) are overridden by mac-specific versions that use macOS-compatible flags
- **Idempotent installer**: `install.sh` checks for existing installations before acting — safe to re-run
- **Single-source macOS setup**: `install.sh` is the sole entry point for macOS — Homebrew packages (via `Brewfile`), shell framework, dotfiles, fonts, and system defaults are all managed here (not in Ansible)
- **Brewfile for packages**: Add/remove Homebrew formulae and casks in `Brewfile`, not in `install.sh`

## Ansible Integration

The homelab repo's Ansible roles clone this repo and run `stow` to deploy dotfiles on managed hosts. The repo URL and branch are configured via the `common_dotfiles_repo`, `common_dotfiles_version`, and `common_dotfiles_dest` variables in the homelab's Ansible role defaults.
