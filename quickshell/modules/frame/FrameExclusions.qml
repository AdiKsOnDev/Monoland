pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

// Reserves screen space for the frame bands. The drawing window ignores
// exclusion (it must span the whole screen to draw seamless corners), so
// three tiny invisible windows reserve the left/right/bottom edges instead.
// The top edge is already reserved by BarWindow's exclusive zone.
Scope {
    id: root

    required property var screen

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
