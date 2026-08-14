pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Material Design 3 token layer for the settings surfaces.
//
// MD3 expects a tonal palette; pywal only hands us a flat 16-colour scheme, so
// the surface ladder is mixed here rather than read from the scheme. The steps
// blend toward a neutral tint instead of using Qt.lighter because value-scaling
// barely moves a near-black background — #050402 lightened is still #050402.
Singleton {
    id: root

    function mix(a, b, t) {
        const x = Qt.color(a), y = Qt.color(b)
        return Qt.rgba(x.r + (y.r - x.r) * t,
                       x.g + (y.g - x.g) * t,
                       x.b + (y.b - x.b) * t, 1)
    }

    function luminance(c) {
        const x = Qt.color(c)
        return 0.299 * x.r + 0.587 * x.g + 0.114 * x.b
    }

    function onColorFor(c) { return luminance(c) > 0.6 ? "#101010" : "#ffffff" }

    // Direction the surface ladder climbs: whichever way the theme leaves room.
    readonly property color tint: Colors.isLight ? "#000000" : "#ffffff"

    // MD3 surfaces carry a trace of the accent; the 0.03 primary blend is that
    // tint, applied before the neutral step so every level inherits it.
    function surfaceAt(level) {
        return mix(mix(Colors.background, primary, 0.03), tint, level)
    }

    // ── Colour roles ──────────────────────────────────────────────────────
    //
    // MD3 names foreground roles "onSurface"/"onPrimary", but QML reserves
    // on<Capital> for signal handlers: declaring `onSurface` next to `surface`
    // silently yields an undefined property, which Text renders as pure black.
    // Hence the textOn* prefix — do not rename these back.
    readonly property color surface:                 surfaceAt(0.00)
    readonly property color surfaceContainerLowest:  surfaceAt(0.02)
    readonly property color surfaceContainerLow:     surfaceAt(0.045)
    readonly property color surfaceContainer:        surfaceAt(0.07)
    readonly property color surfaceContainerHigh:    surfaceAt(0.10)
    readonly property color surfaceContainerHighest: surfaceAt(0.13)

    readonly property color textOnSurface:        Colors.primaryText
    readonly property color textOnSurfaceVariant: Colors.secondaryText

    readonly property color outline:        mix(Colors.background, tint, 0.30)
    readonly property color outlineVariant: mix(Colors.background, tint, 0.16)

    readonly property color primary:            Colors.chipIconActive
    readonly property color textOnPrimary:          onColorFor(primary)
    readonly property color primaryContainer:   mix(Colors.background, primary, 0.28)
    readonly property color textOnPrimaryContainer: Colors.isLight
        ? mix(primary, "#000000", 0.55)
        : mix(primary, "#ffffff", 0.55)

    readonly property color secondaryContainer:   surfaceAt(0.16)
    readonly property color textOnSecondaryContainer: Colors.primaryText

    readonly property color error: Colors.accents[0]

    // State-layer opacities (MD3 spec values)
    readonly property real hoverOpacity:    0.08
    readonly property real pressedOpacity:  0.12
    readonly property real disabledOpacity: 0.38

    // ── Shape ─────────────────────────────────────────────────────────────
    readonly property int cornerXs:    4
    readonly property int cornerS:     8
    readonly property int cornerM:    12
    readonly property int cornerL:    16
    readonly property int cornerXl:   28
    readonly property int cornerFull: 999

    // ── Motion ────────────────────────────────────────────────────────────
    readonly property int durShort:  100
    readonly property int durMedium: 200
    readonly property int durLong:   350
    readonly property int easingStandard:   Easing.OutCubic
    readonly property int easingEmphasized: Easing.OutQuint

    // ── Typography ────────────────────────────────────────────────────────
    readonly property string fontFamily: "Poppins"
    readonly property string iconFamily: "JetBrainsMono Nerd Font"

    readonly property int headlineSmall: 24
    readonly property int titleLarge:    20
    readonly property int titleMedium:   16
    readonly property int titleSmall:    14
    readonly property int bodyLarge:     15
    readonly property int bodyMedium:    13
    readonly property int bodySmall:     12
    readonly property int labelLarge:    14
    readonly property int labelMedium:   12
    readonly property int labelSmall:    11
}
