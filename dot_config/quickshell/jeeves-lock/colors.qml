pragma Singleton
import QtQuick

// Jeeves After Dark — palette tokens sourced from
//   ~/.local/share/plasma/desktoptheme/jeeves-after-dark/colors  (KDE palette)
// and consistent with the Palace Thermal Deck widget's existing Jeeves palette.
//
// All values are documented; no magic numbers.
QtObject {
    // ---- Backgrounds (dark plum) ----
    readonly property color backgroundDeep: "#0d0914"  // RGB 13,9,20   — deepest plum (Colors:Complementary BackgroundNormal)
    readonly property color cardSurface:   "#171022"  // RGB 23,16,34  — card surface (Colors:Button BackgroundNormal)
    readonly property color cardHover:     "#21152F"  // RGB 33,21,47  — hover (Colors:Button BackgroundAlternate)

    // ---- Accents (lavender for focus/active) ----
    readonly property color lavenderAccent: "#a970ff"  // RGB 169,112,255 — focus (Colors:Button DecorationFocus)
    readonly property color lavenderHover:  "#d66bff"  // RGB 214,107,255 — hover (Colors:Button DecorationHover)

    // ---- Status / sensor tints (consistent with palace widget) ----
    readonly property color pinkAccent:     "#ff5fcb"  // CPU
    readonly property color cyanAccent:     "#5fd6ff"  // GPU
    readonly property color acidGreen:      "#6fff8b"  // HEALTHY (stateHealthy)
    readonly property color amberWarn:      "#ffd24a"  // WARN    (stateWarn)
    readonly property color redAlert:       "#ff6b3d"  // ALERT   (stateAlert)
    readonly property color plumAccent:     "#b78dff"  // RAM
    readonly property color blueAccent:      "#5f9eff"  // VRAM

    // ---- Foregrounds ----
    readonly property color foregroundNormal:   "#f3ecff"  // RGB 243,236,255 — primary text
    readonly property color foregroundInactive: "#8878a0"  // RGB 136,120,150 — secondary text
    readonly property color foregroundLink:     "#59e1ff"  // RGB 89,225,255  — link/CTA

    // ---- Borders ----
    readonly property color borderSubtle:       "#6e5fb299"  // ~45% alpha violet

    // ---- Fonts (matches hyprland.lua cursor theme name → font.family fallback chain) ----
    readonly property string fontFamily: "Hack"
}
