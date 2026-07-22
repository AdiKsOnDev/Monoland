pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

// Reserves screen space for the frame. The drawing windows and the bar all
// ignore exclusion zones (they must span the full screen edge-to-edge for
// seamless corners), so tiny invisible windows reserve every edge instead:
// barHeight on top, band thickness on the other three.
Scope {
    id: root

    required property var screen

    ExclusionZone { anchors.top: true; exclusiveZone: Frame.barHeight }
    ExclusionZone { anchors.left: true }
    ExclusionZone { anchors.right: true }
    ExclusionZone { anchors.bottom: true }

    component ExclusionZone: PanelWindow {
        screen: root.screen
        exclusiveZone: Frame.thickness
        mask: Region {}
        color: "transparent"
        implicitWidth: 1
        implicitHeight: 1
    }
}
