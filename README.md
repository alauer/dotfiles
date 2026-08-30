# dotfiles

A chezmoi-managed snapshot of a Hyprland + Omarchy desktop. Portable across machines.

## What this is

- **Single source of truth**: every config in `~/` is reflected in this repo
- **Public** — no secrets are checked in (no SSH keys, no age keys, no API tokens)
- **Templated identity**: prompts for `name`, `email`, and `githubUsername` on first apply
- **Starship prompt preserved** as a static file

## Structure

```
.
├── .chezmoi.yaml.tmpl      # prompts for identity, sets osid
├── .chezmoiignore          # ignores browsers, agent runtimes, runtime state
├── .devcontainer/          # dev container for trying it out
├── darwin/                 # macOS-only artifacts (iterm profile)
├── dot_bashrc.tmpl         # bash interactive config (Omarchy-aware)
├── dot_bash_profile        # bash login shell entry point
├── dot_bash_logout         # bash logout
├── dot_XCompose.tmpl       # X11 compose (templated identity)
├── dot_config/             # XDG_CONFIG_HOME contents
│   ├── alacritty/
│   ├── autostart/
│   ├── btop/
│   ├── chromium-flags.conf
│   ├── foot/
│   ├── ghostty/
│   ├── git/
│   ├── hypr/
│   ├── imv/
│   ├── kitty/
│   ├── lazygit/
│   ├── mimeapps.list
│   ├── mise/
│   ├── nvim/               # LazyVim-based
│   ├── obsidian/           # config files only (no vault contents)
│   ├── omarchy/            # Omarchy desktop framework
│   ├── starship.toml       # ⭐ Starship prompt — preserved verbatim
│   ├── systemd/            # user services + symlinks
│   ├── tmux/
│   └── xournalpp/
├── dot_local/
│   ├── bin/                # mise wrappers + omarchy-* helpers
│   └── share/applications/ # desktop entries for Omarchy webapps
└── private_dot_ssh/        # mode 0600 SSH files
    ├── authorized_keys.tmpl  # pulls from GitHub by username
    └── config.tmpl           # 1Password SSH agent config
```

## Bootstrapping a new machine

```bash
sh -c "$(curl -fsLS chezmoi.io/get)" -- init --apply <this-repo-url>
```

On first apply, chezmoi will prompt for:

- **name** — display name (used in `~/.gitconfig` via XDG path and `~/.XCompose`)
- **email** — git email
- **githubUsername** — used to populate `~/.ssh/authorized_keys` from GitHub

Subsequent applies skip the prompts.

## Prerequisites

The target machine needs:

- A Hyprland / Omarchy installation
- `mise` (for the wrapper scripts in `~/.local/bin/`)
- `bun` (path templated into `~/.bashrc`)

## What's NOT in this repo

By design (via `.chezmoiignore`):

- Browser profiles and caches (`chromium`, `vivaldi`, `google-chrome`, `microsoft-edge`, `BraveSoftware`)
- Agent runtimes (`.pi`, `.claude`, `.codex`, `.opencode`, `.qmd`)
- Secrets (`.1password`, `.ssh/known_hosts*`, `.pki`, `.mozilla`)
- Game state (`.factorio`, `.steam`)
- Input method runtime state (`fcitx*`, `ibus`)
- User data (`Documents`, `Downloads`, `Music`, `Pictures`, `Projects`, `Videos`, `Work`)

## Notes

- `private_dot_ssh/encrypted_private_id_rsa.age` is **not** checked in. Generate your own SSH keypair on the new machine; `authorized_keys` will pull from your GitHub profile automatically.
- The `dot_config/omarchy/` tree is the Omarchy framework's user-customization dir; it expects Omarchy to be installed at `/usr/share/omarchy/`.
- macOS users: `darwin/iterm-profile.json` exists but isn't auto-applied (no `dot_iterm-profile.json.tmpl` mapping).
