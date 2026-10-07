# dotfiles

A [chezmoi](https://www.chezmoi.io)-managed snapshot of Aaron Lauer's user
dotfiles and environment preferences for a fleet of Omarchy (Hyprland/Arch)
machines. The baseline is seeded from **tachikoma-2** (laptop); **tachikoma-1** (desktop)
and future machines inherit it, and a theme repo restyles it.

Classic dotfiles scenario: everything under `$HOME` that is *configuration*.
Public repo — no secrets checked in; sensitive material is age-encrypted or kept
in the per-host `~/.env`.

> **AI agents:** read [`AGENTS.md`](AGENTS.md) before touching anything. The
> architecture is specified in [`docs/SDD-portable-baseline.md`](docs/SDD-portable-baseline.md).

## What this is

- **Single source of truth** for user config on every machine
- **Three layers** — *base* (this repo), *platform gates* (distro family, Omarchy,
  laptop, CPU vendor; template partials in `.chezmoitemplates/`), and *theme*
  (separate repo: palette, prompt, wallpaper, screensaver). Never branches or
  per-hostname forks
- **Packages and plugins as data** — `.chezmoidata/packages.yaml` and
  `omarchy.yaml`, installed by opt-in scripts (`CHEZMOI_INSTALL=1`)
- **Public-safe by construction** — secrets via age encryption (`encrypted_*.age`)
  or the host-local `~/.env` pattern
- **Drift-free doctrine** — a pre-commit hook blocks commits unless
  `chezmoi diff` is clean (source is a faithful snapshot of the home it manages)

## What this is NOT

- **Not** `~/.hermes` (machine intelligence: identity, skills, memories, agent
  config) — explicitly out of scope, ignored by design
- **Not** system files outside `$HOME` (udev rules, `/usr/local/bin`, NetworkManager
  dispatcher) — hand-managed per host
- **Not** a provisioner for the OS itself — the package *lists* live here, but the
  install scripts are inert unless `CHEZMOI_INSTALL=1`, so a normal `apply` never
  installs anything

## Structure

```
.
├── AGENTS.md               # rules for AI agents working in this repo
├── docs/
│   ├── SDD-portable-baseline.md  # architecture spec (start here)
│   └── env.example               # expected ~/.env keys (no values)
├── .chezmoidata/
│   ├── packages.yaml       # package groups, gated by platform
│   └── omarchy.yaml        # Omarchy shell plugins, tagged core|laptop|optional
├── .chezmoitemplates/      # platform gates: is-arch, is-omarchy, is-laptop, is-intel
├── .chezmoiscripts/        # run_onchange_after_ install scripts (opt-in guard)
├── .chezmoi.yaml.tmpl      # config template: age recipient, identity prompts, osid
├── .chezmoiignore          # templated: runtime state, browsers, secrets, .hermes
├── .githooks/pre-commit    # drift gate: commits blocked unless chezmoi diff clean
├── .devcontainer/          # dev container for safe experiments
├── darwin/                 # macOS reference artifacts (not auto-applied)
├── dot_bashrc.tmpl         # bash: Omarchy rc + ~/.env sourcing + brew/starship/fastfetch
├── dot_config/
│   ├── alacritty/ foot/ ghostty/ kitty/ tmux/   # terminals
│   ├── btop/                                    # system monitor (templated theme link)
│   ├── hypr/                                    # Hyprland (lua configs)
│   ├── nvim/                                    # LazyVim-based
│   ├── omarchy/                                 # Omarchy: agent default, hooks, branding
│   ├── git/ mise/ lazygit/ # dev tooling (starship.toml: theme-aware template in omarchy/)
│   └── systemd/user/                            # user services + symlink targets
├── dot_local/
│   ├── bin/                # mise wrappers + agent CLI shims (claude, codex, pi, …)
│   └── share/applications/ # webapp desktop entries
└── private_dot_ssh/        # 0600: config.tmpl (1Password agent), authorized_keys.tmpl
```

## Bootstrapping a new machine

```bash
# Prereqs: Omarchy installed; the existing password-protected age key restored to
# ~/.config/chezmoi/key.txt (chmod 600); tailscale/GitHub SSH access.

sh -c "$(curl -fsLS chezmoi.io/get)" -- init --apply git@github.com:alauer/dotfiles.git
git -C ~/.local/share/chezmoi config core.hooksPath .githooks   # arm the drift gate
```

First apply prompts for `name`, `email`, `githubUsername` (cached afterwards via
`promptStringOnce`). Then:

1. Create `~/.env` from `docs/env.example` (values by hand — never committed).
   To install packages and Omarchy plugins on a fresh machine, run the apply with
   `CHEZMOI_INSTALL=1` (review `chezmoi diff` first).
2. `omarchy theme install <theme-repo>` then `omarchy theme set <name>`.
3. System-level setup (out of scope here) and machine-intelligence onboarding are
   separate household processes.
4. Verify: `chezmoi diff` must be empty; `chezmoi doctor` clean.

Full checklist: `docs/SDD-portable-baseline.md` §7.

## Day-to-day workflow

```bash
chezmoi edit ~/.config/foo        # edit source, apply when satisfied
chezmoi re-add <path>             # live config is newer → sync INTO repo
chezmoi add <path>                # track a new file from $HOME
chezmoi add --encrypt <path>      # track a secret (age)
chezmoi diff                      # what would apply change?
chezmoi cd && git commit && git push   # pre-commit hook enforces clean diff
```

Platform differences follow the SDD layer model: wrap the difference in
`{{ if includeTemplate "is-laptop" . }}` (or `is-omarchy`, `is-intel`, `is-arch`), or
ignore the whole file in `.chezmoiignore`. Looks belong in the theme. Never fork a
file per hostname.

## Per-machine environment (`~/.env`)

Per-machine values (IPs, MACs, host-specific paths, tokens for local tools) live
in `~/.env`, mode 0600, sourced by `.bashrc` via `set -a`. The repo ships
`docs/env.example` documenting expected keys — **values never enter
git**.

## Encryption

age, single fleet recipient (public key in `.chezmoi.yaml.tmpl`), one identity
file per machine (`~/.config/chezmoi/key.txt`, never committed). Encrypt with
`chezmoi add --encrypt`; files land in source as `encrypted_*.age`.

## Safety rules (everyone, humans and agents)

- `chezmoi apply` on a live machine is a deliberate act — run `chezmoi diff`
  first, every time
- The pre-commit hook is doctrine: never bypass with `--no-verify`
- Runtime state, browser profiles, caches, memories: `.chezmoiignore`, not git
- See `AGENTS.md` for the full agent contract
