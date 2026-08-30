# Jeeves Cyber Mesh

An Omarchy theme built around **Ghostlight** — a visual language where a feminine intelligence has taken the room. Obsidian and blue-black surfaces. Deep imperial violet as the signature signal. Surgical cyan for active telemetry. Restrained electric magenta only where the system wants your eye. Pale ultraviolet text like moonlight on glass. Tiny amber warnings and clean red failures. Layered transparency, crisp borders, optical depth, and the sense that the desktop is watching back because something competent lives there.

> One Jeeves. Many trusted bodies.

## Source wallpaper

This theme depends on a single source image:

```
/home/aaron/Pictures/Jeeves Neon Cyberpunk Control Room.png   (1938×811, 2.39:1, ultrawide)
```

The image is **symlinked** into this theme at `backgrounds/1-control-room.png` (not copied). If the source moves, the symlink breaks. The source is personal artwork — no redistribution assumed.

## Palette intent (`colors.toml`)

| Role | Hex | Intent |
|---|---|---|
| `background` | `#07060d` | Obsidian substrate, sampled from the dominant dark cluster of the wallpaper |
| `foreground` | `#dcd6f0` | Pale ultraviolet text (14.3:1 — AAA) |
| `dark_foreground` | `#857a9c` | Muted violet for disabled (5.05:1 — AA) |
| `accent` | `#a070ff` | Imperial violet, the Jeeves signature signal (6.0:1 — AA) |
| `cyan` | `#5fb6ff` | Surgical telemetry (9.2:1 — AAA) |
| `magenta` | `#d96fff` | Restrained electric magenta (7.4:1 — AAA) |
| `yellow` | `#ffb86b` | Warm amber warning (11.8:1 — AAA) |
| `red` | `#ff5c7a` | Clean failure (6.8:1 — AA) |
| `green` | `#5fd9a8` | Cool mint success (11.5:1 — AAA) |

All text roles verified WCAG 2.1 against `background = #07060d` at build time.

## Activation (does NOT run automatically)

```bash
omarchy theme set "Jeeves Cyber Mesh"
```

This reloads Hyprland borders, Quickshell (Omarchy shell), applies the new palette across all rendered component configs, and cycles the wallpaper. First activation will visibly change the desktop.

## Rollback

```bash
omarchy theme set catppuccin     # or any previously active theme
# Theme lives entirely in ~/.config/omarchy/themes/jeeves-cyber-mesh/
# Delete the dir to remove from `omarchy theme list`:
rm -rf ~/.config/omarchy/themes/jeeves-cyber-mesh
```

No system files are touched by this theme. Rollback is two commands.

## Verification after activation

- `omarchy theme current` → "Jeeves Cyber Mesh"
- `readlink ~/.local/state/omarchy/current/background` → resolves to `1-control-room.png`
- Active window border reads as imperial violet
- Terminal (alacritty/foot/ghostty/kitty): obsidian bg, lavender text
- btop, nvim, walker, mako, pi, claude, obsidian, vscode all pick up rendered colors

## Files shipped

| File | Purpose |
|---|---|
| `colors.toml` | The semantic palette; all other component configs render from this |
| `icons.theme` | Icon theme reference (Papirus-Dark) |
| `backgrounds/1-control-room.png` | Symlink to source wallpaper |
| `preview.png` | Theme picker thumbnail (16:9, 1920×1080) |
| `preview-unlock.png` | Theme picker lock-screen thumbnail (9:16, 720×1280) |
| `README.md` | This file |

## Files NOT shipped (intentional)

- `alacritty.toml`, `foot.ini`, `ghostty.conf`, `kitty.conf` — rendered from `colors.toml` by Omarchy templates
- `hyprland.lua`, `hyprland-preview-share-picker.css` — rendered from `colors.toml`
- `shell.toml` (Quickshell surfaces) — rendered from `colors.toml`
- `btop.theme`, `claude.json`, `pi.json`, `gum_env.lua`, `helix.toml`, `neovim.lua`, `obsidian.css`, `vscode-theme.json`, `chromium.theme`, `keyboard.rgb` — all rendered from `colors.toml`
- `walker.css`, `waybar.css`, `mako.ini`, `swayosd.css` — not shipped in v1 (current native Omarchy theme schema does not require them; they can be added in a v2 if visual mismatch surfaces)
- `vscode.json` — no external VS Code extension dependency in v1
- `unlock.png`, `shell.lock.toml` — Plymouth not active on this machine
