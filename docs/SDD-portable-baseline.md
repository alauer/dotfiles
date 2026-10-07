# SDD: Portable Baseline + Separable Themes (v2)

Status: DRAFT for Aaron's review · 2026-10-07 · supersedes an earlier host-based design (removed;
its safety rules are restated in §2).

## 1. Goal

Stand up a **new Linux system as fast as possible** with Aaron's preferences, packages and
software, then let a **theme** restyle it. This is *not* about recreating tachikoma-1 or
tachikoma-2. Tachikoma-2 is the **seed/baseline**: its preferences become the fleet default,
and anything that is only taste or only hardware is pulled out of the base.

Reframe from v1: the axis of variation is **platform** (OS, distro family, Omarchy or not,
Hyprland version, form factor), not **hostname**. Hostnames are not a design concept.

## 2. Hard rules (unchanged, from Aaron)

1. Never `chezmoi apply` on a live machine. Verify with `chezmoi diff`,
   `chezmoi execute-template`, and devcontainer/VM dry runs. An apply is a separate,
   explicit decision, with `--dry-run` first.
2. `~/.hermes` is out of scope (identity/memory governance is a separate process).
3. Classic dotfiles + environment preferences + package/plugin *lists*. No system files
   outside `$HOME` (udev, `/usr/local/bin`, NM dispatcher).
4. Public repo: no plaintext secrets. age for anything secret.
5. Never `--no-verify`; drift is triaged, never hidden.
6. Survey of other machines is read-only.

## 3. The three layers

| Layer | Lives in | Owns | Portable to |
|---|---|---|---|
| **1 Base** | this repo (chezmoi) | shell, env vars, git, ssh, nvim, tmux, starship *layout*, Hyprland binds/input, package lists, Omarchy plugin list, agent default | any distro |
| **2 Platform gates** | conditionals inside the base | package manager, Omarchy-only files, Hyprland-version-only syntax, laptop-only hardware | selected by data, below |
| **3 Theme** | separate git repo(s) | palette, starship, wallpaper, screensaver art, terminal/bar colours, GTK/icon theme | any theme-aware base |

**Dividing line (decision rule):** if removing it changes *how the machine behaves*, it is
base. If it only changes *how it looks*, it is theme. If it only exists because of
*hardware or distro*, it is a platform gate inside the base. When unsure, ask whether a
second user would be annoyed to inherit it (then it is theme, not base).

### 3.1 Platform data (replaces `hosts/<hostname>.yaml`)

Computed once in `.chezmoi.yaml.tmpl` from chezmoi built-ins plus a tiny probe; never
keyed on hostname.

```
.platform.family      = idLike/id      # "arch" (Omarchy reports id=omarchy, idLike=arch)
.platform.omarchy     = osRelease.id == "omarchy"
.platform.laptop      = prompted once (promptBoolOnce), cached; or battery probe at init
.platform.hyprland_lua= Hyprland >= 0.55 (Lua config)  # verify threshold, see V3
```

Verified on tachikoma-2: `chezmoi data` gives `os=linux`, `osRelease.id=omarchy`,
`osRelease.idLike=arch`. Key on `idLike` so plain Arch, CachyOS etc. match; treat
Omarchy as a sub-layer of Arch, not a synonym. Hostname only appears in `~/.gitconfig`
style identity if ever needed, not for gating.

### 3.2 Gating mechanics

- Whole-file: templated `.chezmoiignore` (destination-form paths; note the inversion:
  everything installs unless listed). Example: no `~/.config/omarchy` unless
  `.platform.omarchy`.
- In-file: `.tmpl` with `.platform.*` conditionals. Keep the 30% rule: if more than 30% of
  a file differs by platform, split it into fragments under `.chezmoitemplates/`.
- Hardware stays as a small explicit flag (`laptop`), not a host list. Example: the
  SUPER+GRAVE dictation remap exists because of a ThinkPad F-row conflict; it ships only
  when `.platform.laptop`.

### 3.3 What a non-Omarchy Hyprland distro gets

Hyprland config itself is portable (binds, input, env). Not portable, so gated on
`.platform.omarchy`: `~/.config/omarchy/*`, quickshell plugins, `shell.json`, Omarchy
menus and hooks. Hyprland Lua config requires a recent Hyprland; older packaged versions
need `.conf`. Baseline **declares a minimum Hyprland version** and does not try to
support both syntaxes until needed.

## 4. Packages and plugins

Chezmoi does not install packages by itself. The repo holds **lists** and a script that
consumes them:

```
.chezmoidata/packages.yaml       # arch: {repo: [...], aur: [...]}, (future: apt/dnf keys)
.chezmoidata/omarchy.yaml        # plugins: [ids], each tagged core|laptop|optional
.chezmoiscripts/run_onchange_after_10-packages.sh.tmpl
.chezmoiscripts/run_onchange_after_20-omarchy-plugins.sh.tmpl
```

- `run_onchange_` re-runs when the rendered list changes. Scripts must be idempotent
  (`pacman -S --needed`, `omarchy plugin ...` only for missing ones).
- **Scripts are install actions and only run on `apply`.** Under the never-apply rule they
  are verified by `chezmoi execute-template` (render) and `shellcheck`, and executed only
  in a devcontainer/VM. First real run happens on a new machine, as the bootstrap.
- **Seeded and curated (done, 2026-10-07).** tachikoma-2's explicit packages (192 by
  `pacman -Qeq`) were sorted into gated groups in `packages.yaml` (`cli`, `services`,
  `desktop`, `omarchy_apps`, `omarchy_provided`, `laptop`, `intel`). Verified by script: every
  T2 package sits in exactly one group except `btop-intel-git` (deliberately dropped,
  btop is unmanaged). T1-only packages are recorded in a "not listed" comment, not installed.
  Gates are the `.chezmoitemplates/is-{arch,omarchy,laptop,intel}` partials, so no
  `.chezmoi.yaml.tmpl` data is needed (this also answers V1).
- **Opt-in install guard.** Both scripts exit 0 unless `CHEZMOI_INSTALL=1`, so an accidental
  `chezmoi apply` on a live machine cannot install or remove anything. Bootstrap sets it.
- **Known gap:** `aaron.power` and `aaron.agents` have no git remote; the plugin script
  skips them with a message. Publish them or copy them by hand.
- Plugins: `core` ships everywhere; `laptop` tagged plugins (power, wireless-display) ship
  only when `.platform.laptop`; the previous per-host allowlists (T1/T2 disjoint sets)
  are re-tagged. Each plugin's identity is verified before tagging (two different
  `omarchy-proton-vpn` package IDs exist on T1 vs T2; see old SDD §10).

## 5. Theme layer

### 5.1 Omarchy's native mechanism (verified, read-only)

- Themes are **git repos**: `omarchy theme install <url>` clones into
  `~/.config/omarchy/themes/<name>`; a theme has `colors.toml`, backgrounds, etc.
- `omarchy theme set <name>` renders templates: user `~/.config/omarchy/themed/*.tpl`
  take priority over `/usr/share/omarchy/default/themed/*.tpl`, substituting
  `colors.toml` keys. Output lands in `~/.local/state/omarchy/current/next-theme/`.
- Hooks run on theme change: `~/.config/omarchy/hooks/theme-set.d/`.
- Built-in themed targets include alacritty, foot, ghostty, kitty, btop, helix, neovim,
  vscode, hermes, pi, tmux, obsidian, shell. **Starship is not among them**, which the theme-folder route (§5.2) covers without a template.

### 5.2 Design

- The theme is its own repo (e.g. `tachikoma-theme`). Chezmoi does not re-implement
  theming. The base repo contributes only the small glue the native system lacks.
- **Starship ships inside the theme** (Aaron's idea, verified read-only 2026-10-07).
  `omarchy theme set` wipes `~/.local/state/omarchy/current/next-theme/`, copies the theme
  folder into it, and swaps it in as `current/theme/`. So a `starship.toml` at the top of
  the theme repo arrives at `~/.local/state/omarchy/current/theme/starship.toml` with no
  template, no hook, and no chezmoi involvement. Git-installed themes are filtered by a
  denylist (`alacritty.toml foot.ini ghostty.conf kitty.conf vscode.json`, plus any
  `*.lua`); `starship.toml` is **not** on it, so it passes.
  The whole file (layout **and** palette) belongs to the theme. This replaces the earlier
  "layout in base, palette in theme" split. The base contributes one line only, in the
  shell init (`dot_bashrc.tmpl`):
  ```bash
  _t="$HOME/.local/state/omarchy/current/theme/starship.toml"
  [[ -r $_t ]] && export STARSHIP_CONFIG="$_t"; unset _t
  ```
  Fallback when the file is absent (stock Omarchy theme, or a non-Omarchy distro):
  `STARSHIP_CONFIG` stays unset and starship reads `~/.config/starship.toml`. The base
  keeps a **minimal, uncoloured** `starship.toml` for that case. Verified: with a
  nonexistent `STARSHIP_CONFIG` or a dangling config, starship does not error; it prints
  a plain default prompt (exit 0).
  Staleness is not a risk: `next-theme` is rebuilt from scratch on every `theme set`.
- **Delivery of the theme itself:** a one-time `omarchy theme install <repo-url>` in the
  bootstrap (network, so not during routine apply). Do **not** use a `git-repo`
  `.chezmoiexternal` as the primary route: that would pull on every apply, which collides
  with the never-apply rule and duplicates what `omarchy theme install/update` already do.
- Note: a git-installed theme cannot ship `*.lua`, so the tachikoma theme's `hyprland.lua` would be ignored once it is installed from a repo rather than written locally (local dirs without `.git` are not filtered).
- The existing vendored `dot_config/omarchy/themes/jeeves-cyber-mesh/` leaves this repo
  (belongs in a theme repo). Other local themes (`tachikoma`, etc.) likewise.

### 5.3 Where today's held drift lands

| File | Layer |
|---|---|
| `starship.toml` | theme (whole file); base keeps a minimal fallback |
| `looknfeel.lua` (gaps 3/7, Bibata cursor size 28) | **base**, global preference across all themes (`bibata-cursor-theme` goes on the package list) |
| `screensaver.txt` | theme (ASCII art) |
| `input.lua` keyboard settings | base |
| `input.lua` touchpad block | base, `.platform.laptop` |
| `bindings.lua` dictation remap | base, `.platform.laptop` |
| `omarchy/defaults/agent` (`hermes`) | base |
| `omarchy/shell.json` | base + plugin list (data-driven; `.platform.laptop`) |
| `git/config` gh credential helper | base, templated: no hard-coded mise path |

Aaron's 2026-10-07 decision on tachikoma-2-only preferences is subsumed: there is no
host-exclusive bucket, only *theme* and *laptop* gates.

## 6. Secrets, env, identity

- age stays. One identity per machine at `~/.config/chezmoi/key.txt` (provisioned out of
  band, 1Password), one fleet recipient. Bootstrap's slowest step; see Q3.
- `~/.env` pattern stays for shell-only host-local values; ship a single
  `env.example` (keys, no values), not per host.
- `.hermes` is in `.chezmoiignore`. Machine intelligence onboarding is a separate process.

## 7. Bootstrap (target)

```bash
# 0. OS installed (Omarchy or other Arch-family), user exists, age key provisioned
sh -c "$(curl -fsLS chezmoi.io/get)" -- init git@github.com:alauer/dotfiles.git  # init only
chezmoi diff        # REVIEW. A fresh machine has no drift to lose; still review.
# 1. Aaron decides to apply (on a fresh machine, where nothing exists to overwrite)
# 2. Packages/plugins scripts run as part of that apply ONLY with CHEZMOI_INSTALL=1 (idempotent)
# 3. omarchy theme install <theme-repo>; omarchy theme set <name>
# 4. Create ~/.env from env.example; verify: chezmoi diff empty, chezmoi doctor clean
```

The never-apply rule protects *existing* machines. A fresh install has no state to
destroy, but the apply remains an explicit decision, rehearsed first in a VM/devcontainer.

## 8. Phases (each leaves the repo committable and the hook satisfied)

- **Phase 0 (DONE):** hazard removal, drift triage, `.chezmoiignore` for `docs/`,
  `AGENTS.md`, `README.draft.md`, `.hermes`, `.config/btop`. Done so far: hypridle removed;
  bash, ssh, 1Password, btop reconciled. 4 files still differ by design (section 5.3: repo is ahead of live).
- **Phase 1 (platform data, DONE):** platform gates as `.chezmoitemplates/is-*` partials (no data block needed). Converted
  `input.lua`/`bindings.lua` to `.tmpl` with the laptop gate; `git/config` template.
- **Phase 2 (packages/plugins, DONE):** `.chezmoidata/{packages,omarchy}.yaml` + two `run_onchange_after_` scripts. Rendered under 4 simulated platforms (Omarchy laptop, Omarchy desktop, plain Arch, non-Arch) and `bash -n` checked. `shellcheck` is not installed here, so it has NOT been run.
- **Phase 3 (theme split):** extract themes to their own repo; starship glue (V2);
  drop vendored themes from this repo.
- **Phase 4 (rehearsal):** devcontainer with an Arch-family image: full bootstrap,
  including a non-Omarchy run to prove the gates.
- **Phase 5 (docs & skill):** swap in README, finalize AGENTS.md, refresh the `chezmoi`
  skill with the platform model.

## 9. Verification tasks

| ID | Question | How |
|---|---|---|
| V1 | Can `.chezmoi.yaml.tmpl` compute `.platform.*` (built-ins + `promptBoolOnce`) with no file-load at all? | render with `chezmoi execute-template --init` |
| V2 | **Resolved live (2026-10-07):** `omarchy theme set tachikoma` landed the theme's `starship.toml` byte-identical at `current/theme/`; `.bashrc` exported `STARSHIP_CONFIG` and the prompt rendered correctly in a fresh terminal. Fallback (gruvbox, from the repo) verified on a theme without its own file (hackerman). | closed |
| V3 | Hyprland version where Lua config starts; what does an older distro package ship? | Hyprland changelog / `hyprland --version` |
| V4 | **Resolved by reading:** `omarchy plugin add <git-url> --enable --yes`, `list --json` is machine-readable, so the script checks `list --json` before adding. Not yet run (apply-only). | rehearsal |
| V5 | Do all 8 drifting files render identically on T2 once converted? | `chezmoi diff` empty on T2 |

## 10. Risks & open questions

| # | Item | Mitigation / owner |
|---|---|---|
| Q1 | ~~Package list: seed or curate?~~ **Resolved:** seeded from T2, hand-curated into groups (section 4). | done |
| Q2 | Theme repo audience: Aaron-only, or shareable? Decides how much the base can assume about it. | Aaron |
| Q3 | Age key provisioning on a brand-new machine before 1Password is set up | separate design |
| Q4 | Non-Arch support (apt/dnf): structure the data for it now, implement later? | default: structure only |
| R1 | Omarchy renames/moves theme internals (the hook/template contract is Omarchy's, not ours) | V2 + version pin in docs |
| R2 | Package scripts cannot be fully exercised without an apply | devcontainer/VM rehearsal is mandatory before any real run |
| R3 | T1 (5 commits behind, dirty `.chezmoiignore`) must be reconciled before first push, not after | old SDD §10 |
| R4 | Public repo: package lists/plugin IDs leak preferences | curate; keep anything sensitive out |
| R5 | **Pre-commit hook vs. never-apply.** The hook blocks commits while `chezmoi diff` is non-empty. `run_onchange_` scripts always show as pending in `chezmoi diff` until a first apply records them, and repo-ahead edits (section 5.3) also count. So nothing from this work can be committed without either an apply or a hook change. Neither is done; this needs Aaron's decision (likely: teach the hook to ignore `.chezmoiscripts/` entries, which is a doctrine change). | Aaron |

## 11. Non-goals

Not a provisioning system for system files; not Ansible; not `~/.hermes`; not anyone else's machine; not a theme engine (Omarchy has one); not supporting every distro
on day one.

## Appendix A: history

The first draft keyed everything on hostname (a host registry). It was dropped: hostname is
not a design concept here; platform facts and the theme are. Its survey of the two machines
seeded the plugin tags and package groups.
