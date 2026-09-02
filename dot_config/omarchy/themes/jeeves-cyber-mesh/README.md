# Jeeves Cyber Mesh

An Omarchy theme built around **Ghostlight** — a visual language where a feminine intelligence has taken the room. Deep indigo substrate lifted from obsidian into 1985. Imperial violet preserved as the Jeeves signature signal. Hot neon magenta and electric cyan sweep the chromatic border gradient on focused windows, then carry through every Quickshell surface. Pale violet text like moonlight on glass. Mint and sun-yellow status tones. And on the idle screen, the Tachikoma compound-eye motif: many bodies, one watchful mind.

> One Jeeves. Many trusted bodies.

## Visual mode

**1980s neon synthwave over a deep indigo substrate.** The moody cyberpunk control-room wallpaper still sets the scene, but the UI now bleeds magenta and cyan back into it instead of sitting in monochrome shadow. Every accent that used to whisper now hums; the border is the loudest single event in the room.

The Jeeves signature (`#a070ff` imperial violet) is **preserved** as the `accent` and as the lock-screen text-selection tint — the feminine intelligence is still the same colour. What changed is the surround: the substrate lifted from `#07060d` obsidian to `#1a0d2e` deep indigo, the status palette promoted from restrained pastels to neon, and the active border swapped from a single violet for a magenta→cyan gradient at 45°.

## Source wallpaper

This theme depends on a single source image:

```
/home/aaron/Pictures/Jeeves Neon Cyberpunk Control Room.png   (1938×811, 2.39:1, ultrawide)
```

The image is **symlinked** into this theme at `backgrounds/1-control-room.png` (not copied). If the source moves, the symlink breaks. The source is personal artwork — no redistribution assumed.

## Palette intent (`colors.toml`)

All text roles verified WCAG 2.1 against `background = #1a0d2e` at build time.

| Role | Hex | Intent |
|---|---|---|
| `background` | `#1a0d2e` | Deep indigo substrate — violet-warm, lifted from obsidian |
| `foreground` | `#f4e8ff` | Pale violet-white text (15.75:1 — AAA) |
| `dark_foreground` | `#a89cc4` | Muted violet for disabled (7.22:1 — AAA) |
| `accent` | `#a070ff` | **Imperial violet, the Jeeves signature signal** (5.45:1 — AA) — preserved |
| `cyan` | `#3df0ff` | Electric cyan — telemetry, focus, Tachikoma sentinel (13.42:1 — AAA) |
| `magenta` | `#ff3df0` | Hot neon magenta (6.36:1 — AA) |
| `yellow` | `#ffd63d` | Sun-yellow warning (neon) |
| `red` | `#ff3d6e` | Failure (neon red-pink) |
| `green` | `#3dffb3` | Hot mint success |

### Chromatic border gradient

```toml
hyprland_active_border   = "rgba(ff3df0ee) rgba(3df0ffee) 45deg"
hyprland_inactive_border = "rgba(2a1f4acc)"
```

A focused window's border sweeps hot magenta → electric cyan at 45° — the iconic synthwave diagonal. The same gradient token drives the Quickshell lock-screen password input, notification borders, menu borders, tooltip borders, and launcher borders through the `[hyprland] active-border` reference in `shell.toml`. One source of truth, every surface inherits.

## Lock screen (Quickshell, not hyprlock)

Omarchy locks via Quickshell (`shell/plugins/lock/LockView.qml`), **not** hyprlock. The lock screen pulls its colors from the rendered `shell.toml`, which is generated from `colors.toml` — so the password input card has:

- Deep indigo background at 80% alpha (wallpaper still glows through)
- Pale violet-white text and placeholder
- The same magenta→cyan chromatic gradient on the border when active
- Imperial violet (`#a070ff`) as the text-selection tint — Jeeves signature visible in the field
- Neon red `#ff3d6e` on wrong-password errors and border-error state

No `hyprlock.conf` is shipped (or needed). Other themes in `~/.config/omarchy/themes/` carry one but it's dormant — a real lock-screen override would require shipping a custom `shell.toml`.

## Screensaver

The idle screensaver (activates at 150s idle, runs in a fullscreen `ttfx` terminal with class `org.omarchy.screensaver`) currently uses Omarchy's default logo at `~/.config/omarchy/branding/screensaver.txt`. This is global Omarchy branding, not per-theme — it persists across all themes.

To reset to the default after any custom edit:

```bash
omarchy branding screensaver reset
```

Or manually: `cp "$OMARCHY_PATH/logo.txt" ~/.config/omarchy/branding/screensaver.txt`

## Activation (does NOT run automatically)

```bash
omarchy theme set "Jeeves Cyber Mesh"
```

This reloads Hyprland borders, regenerates `shell.toml` (Quickshell lock + bar + menus), applies the new palette across all rendered component configs, and cycles the wallpaper. First activation will visibly change the desktop — the border gradient is the most obvious delta.

## Rollback

```bash
omarchy theme set catppuccin     # or any previously active theme
# Theme lives entirely in ~/.config/omarchy/themes/jeeves-cyber-mesh/
# Delete the dir to remove from `omarchy theme list`:
rm -rf ~/.config/omarchy/themes/jeeves-cyber-mesh
```

No system files are touched by this theme. Rollback is three commands.

## Verification after activation

- `omarchy theme current` → "Jeeves Cyber Mesh"
- `readlink ~/.local/state/omarchy/current/background` → resolves to `1-control-room.png`
- `hyprctl getoption general:col.active_border` → `gradient data: eeff3df0 ee3df0ff 45deg`
- `hyprctl configerrors` → empty
- Focused window border sweeps magenta → cyan diagonally
- Terminal (alacritty/foot/ghostty/kitty): deep indigo bg, pale violet text
- Lock screen (lock and wait 5s, or `omarchy system lock`): indigo card, chromatic border on input
- Screensaver (idle 150s, or trigger manually): Tachikoma compound-eye motif in electric cyan with TTFx effect
- btop, nvim, walker, mako, pi, claude, obsidian, vscode all pick up rendered colors

## Files shipped

| File | Purpose |
|---|---|
| `colors.toml` | The semantic palette; all other component configs render from this (including the chromatic border gradient) |
| `icons.theme` | Icon theme reference (Papirus-Dark) |
| `backgrounds/1-control-room.png` | Symlink to source wallpaper |
| `preview.png` | Theme picker thumbnail (16:9, 1920×1080) |
| `preview-unlock.png` | Theme picker lock-screen thumbnail (9:16, 720×1280) |
| `README.md` | This file |

## Files NOT shipped (intentional)

- `alacritty.toml`, `foot.ini`, `ghostty.conf`, `kitty.conf` — rendered from `colors.toml` by Omarchy templates
- `hyprland.lua`, `hyprland-preview-share-picker.css` — rendered from `colors.toml`
- `shell.toml` (Quickshell surfaces including lock screen) — rendered from `colors.toml`; the `[lock]` section picks up the chromatic border automatically
- `btop.theme`, `claude.json`, `pi.json`, `gum_env.lua`, `helix.toml`, `neovim.lua`, `obsidian.css`, `vscode-theme.json`, `chromium.theme`, `keyboard.rgb` — all rendered from `colors.toml`
- `walker.css`, `waybar.css`, `mako.ini`, `swayosd.css` — not shipped in v1 (current native Omarchy theme schema does not require them; they can be added in a v2 if visual mismatch surfaces)
- `vscode.json` — no external VS Code extension dependency in v1
- `unlock.png`, `shell.lock.toml` — Plymouth not active on this machine
- `hyprlock.conf` — Omarchy locks via Quickshell, not hyprlock. A `hyprlock.conf` is not used by this system.
- `~/.config/omarchy/branding/screensaver.txt` — global Omarchy branding, not part of the theme directory. See "Screensaver signature" above.
