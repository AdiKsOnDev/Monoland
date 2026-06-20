pragma ComponentBehavior: Bound

import QtQuick

// Reusable "water droplet" reveal.
//
// Drives a target Item's scale + opacity when `shown` flips:
//   in  → elastic plop (overshoot + settle, like a drop landing)
//   out → quick squash + fade (anticipation, like a drop merging away)
//
// Usage:
//   Droplet { target: box; shown: root.isOpen; origin: Item.Top }
//
// `origin` controls where it grows from — set it to the edge/corner the
// surface lives at so it blooms out of the bar/screen edge.
Item {
    id: root

    property Item target: null
    property bool shown: false
    property int origin: Item.Center
    property real fromScale: 0.5

    onShownChanged: {
        if (!target) return
        if (shown) outAnim.stop(), inAnim.restart()
        else inAnim.stop(), outAnim.restart()
    }

    Component.onCompleted: {
        if (!target) return
        target.transformOrigin = origin
        target.scale = shown ? 1.0 : fromScale
        target.opacity = shown ? 1.0 : 0.0
    }

    ParallelAnimation {
        id: inAnim
        NumberAnimation {
            target: root.target
            property: "scale"
            to: 1.0
            duration: 520
            easing.type: Easing.OutElastic
            easing.amplitude: 1.0
            easing.period: 0.42
        }
        NumberAnimation {
            target: root.target
            property: "opacity"
            to: 1.0
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: outAnim
        NumberAnimation {
            target: root.target
            property: "scale"
            to: root.fromScale
            duration: 240
            easing.type: Easing.InBack
            easing.overshoot: 1.6
        }
        NumberAnimation {
            target: root.target
            property: "opacity"
            to: 0.0
            duration: 200
            easing.type: Easing.InCubic
        }
    }
}
