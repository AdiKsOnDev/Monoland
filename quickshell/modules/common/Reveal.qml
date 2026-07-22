pragma ComponentBehavior: Bound

import QtQuick

// Refined show/hide for popups & panels: a fade combined with either a short
// directional slide or a subtle scale — smooth deceleration, no elastic bounce.
// Each surface picks a `motion` so they don't all animate the same way.
//
//   motion: "fade" | "scale" | "up" | "down" | "left" | "right"
Item {
    id: root

    property Item target: null
    property bool shown: false
    property string motion: "scale"
    property real distance: 16
    property int inDuration: 300
    property int outDuration: 170

    // Slide offset applied to the target (0,0 when open)
    property Translate off: Translate {}

    function offX(open) {
        if (open) return 0
        if (motion === "right") return distance
        if (motion === "left") return -distance
        return 0
    }
    function offY(open) {
        if (open) return 0
        if (motion === "down") return -distance
        if (motion === "up" || motion === "rise") return distance
        return 0
    }
    function scl(open) {
        return motion === "scale" ? (open ? 1.0 : 0.965) : 1.0
    }

    onShownChanged: {
        if (!target) return
        if (shown) { outAnim.stop(); inAnim.restart() }
        else { inAnim.stop(); outAnim.restart() }
    }

    Component.onCompleted: {
        if (!target) return
        target.transform = [off]
        off.x = offX(shown)
        off.y = offY(shown)
        target.opacity = shown ? 1 : 0
        target.scale = scl(shown)
    }

    ParallelAnimation {
        id: inAnim
        NumberAnimation { target: root.off; property: "x"; to: 0; duration: root.inDuration; easing.type: Easing.OutQuint }
        NumberAnimation { target: root.off; property: "y"; to: 0; duration: root.inDuration; easing.type: Easing.OutQuint }
        NumberAnimation { target: root.target; property: "scale"; to: 1.0; duration: root.inDuration; easing.type: Easing.OutQuint }
        NumberAnimation { target: root.target; property: "opacity"; to: 1.0; duration: Math.round(root.inDuration * 0.6); easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: outAnim
        NumberAnimation { target: root.off; property: "x"; to: root.offX(false); duration: root.outDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: root.off; property: "y"; to: root.offY(false); duration: root.outDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: root.target; property: "scale"; to: root.scl(false); duration: root.outDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: root.target; property: "opacity"; to: 0.0; duration: root.outDuration; easing.type: Easing.InCubic }
    }
}
