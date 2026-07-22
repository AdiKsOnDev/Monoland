pragma ComponentBehavior: Bound

import QtQuick

// Refined show/hide for popups & panels: a fade combined with either a short
// directional slide or a subtle scale — smooth deceleration, no elastic bounce.
// Each surface picks a `motion` so they don't all animate the same way.
//
//   motion: "fade" | "scale" | "up" | "down" | "left" | "right" | "emerge"
//
// "emerge" is for panels attached flush to the screen frame: the panel slides
// fully out from behind the bar/band (no fade — the frame masks it) with a
// squash-stretch anchored at the attached edge, settling smoothly with no
// overshoot. The hidden offset is the panel's full extent plus `distance`, so
// protruding fillets clear the frame too — keep distance >= Frame.radius + seam.
Item {
    id: root

    property Item target: null
    property bool shown: false
    property string motion: "scale"
    property real distance: 16
    property int inDuration: 300
    property int outDuration: 170

    // emerge-only: which frame edge the target is attached to
    property string edge: "top"          // "top" | "bottom" | "left" | "right"
    property real squash: 0.92           // scale along the emerge axis when hidden
    property real bulge: 1.02            // cross-axis scale when hidden
    property real overshoot: 1.012       // single overshoot keyframe on the way in

    // Slide offset applied to the target (0,0 when open)
    property Translate off: Translate {}
    // Non-uniform scale anchored at the attached edge (emerge only)
    property Scale squish: Scale {}

    readonly property bool vertical: edge === "top" || edge === "bottom"

    // Only these motions fade; directional slides and emerge are pure movement
    readonly property bool fades: motion === "fade" || motion === "scale"

    function offX(open) {
        if (open) return 0
        if (motion === "right") return distance
        if (motion === "left") return -distance
        if (motion === "emerge") {
            if (edge === "left") return -((target?.width ?? 0) + distance)
            if (edge === "right") return (target?.width ?? 0) + distance
        }
        return 0
    }
    function offY(open) {
        if (open) return 0
        if (motion === "down") return -distance
        if (motion === "up" || motion === "rise") return distance
        if (motion === "emerge") {
            if (edge === "top") return -((target?.height ?? 0) + distance)
            if (edge === "bottom") return (target?.height ?? 0) + distance
        }
        return 0
    }
    function scl(open) {
        return motion === "scale" ? (open ? 1.0 : 0.965) : 1.0
    }
    // emerge axis/cross scales when hidden
    function axisScl(open) { return open ? 1.0 : squash }
    function crossScl(open) { return open ? 1.0 : bulge }

    onShownChanged: {
        if (!target) return
        if (motion === "emerge") {
            if (shown) { emergeOutAnim.stop(); emergeInAnim.restart() }
            else { emergeInAnim.stop(); emergeOutAnim.restart() }
            return
        }
        if (shown) { outAnim.stop(); inAnim.restart() }
        else { inAnim.stop(); outAnim.restart() }
    }

    // The hidden offset depends on the target's size, which for content-driven
    // panels settles after Component.onCompleted. Re-sync while hidden so a
    // late resize never leaves the panel half-emerged (there is no fade to
    // cover a stale offset).
    function resyncHidden() {
        if (shown || emergeInAnim.running || emergeOutAnim.running) return
        off.x = offX(false)
        off.y = offY(false)
    }

    Connections {
        target: root.target
        enabled: root.motion === "emerge" && !root.shown
        function onWidthChanged() { root.resyncHidden() }
        function onHeightChanged() { root.resyncHidden() }
    }

    Component.onCompleted: {
        if (!target) return
        if (motion === "emerge") {
            target.transform = [squish, off]
            off.x = offX(shown)
            off.y = offY(shown)
            squish.xScale = vertical ? crossScl(shown) : axisScl(shown)
            squish.yScale = vertical ? axisScl(shown) : crossScl(shown)
            // No fade: hidden panels sit fully behind the frame / off-screen
            target.opacity = 1
            return
        }
        target.transform = [off]
        off.x = offX(shown)
        off.y = offY(shown)
        target.opacity = fades ? (shown ? 1 : 0) : 1
        target.scale = scl(shown)
    }

    // Pin the squash origin to the attached edge so the panel grows out of it
    Binding {
        target: root.squish; property: "origin.x"
        value: !root.target ? 0
             : root.edge === "left" ? 0
             : root.edge === "right" ? root.target.width
             : root.target.width / 2
        when: root.motion === "emerge"
    }
    Binding {
        target: root.squish; property: "origin.y"
        value: !root.target ? 0
             : root.edge === "top" ? 0
             : root.edge === "bottom" ? root.target.height
             : root.target.height / 2
        when: root.motion === "emerge"
    }

    ParallelAnimation {
        id: inAnim
        NumberAnimation { target: root.off; property: "x"; to: 0; duration: root.inDuration; easing.type: Easing.OutQuint }
        NumberAnimation { target: root.off; property: "y"; to: 0; duration: root.inDuration; easing.type: Easing.OutQuint }
        NumberAnimation { target: root.target; property: "scale"; to: 1.0; duration: root.inDuration; easing.type: Easing.OutQuint }
        NumberAnimation { target: root.target; property: "opacity"; to: 1.0; duration: Math.round(root.inDuration * 0.6); easing.type: Easing.OutCubic }
    }

    // Out fade only for fading motions; slides keep opacity 1 so the exit
    // movement stays visible

    ParallelAnimation {
        id: outAnim
        NumberAnimation { target: root.off; property: "x"; to: root.offX(false); duration: root.outDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: root.off; property: "y"; to: root.offY(false); duration: root.outDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: root.target; property: "scale"; to: root.scl(false); duration: root.outDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: root.target; property: "opacity"; to: root.fades ? 0.0 : 1.0; duration: root.outDuration; easing.type: Easing.InCubic }
    }

    ParallelAnimation {
        id: emergeInAnim
        NumberAnimation { target: root.off; property: "x"; to: 0; duration: root.inDuration; easing.type: Easing.OutQuint }
        NumberAnimation { target: root.off; property: "y"; to: 0; duration: root.inDuration; easing.type: Easing.OutQuint }
        // Axis scale: squash -> gentle overshoot -> settle. One keyframe, no oscillation.
        SequentialAnimation {
            NumberAnimation {
                target: root.squish; property: root.vertical ? "yScale" : "xScale"
                to: root.overshoot; duration: Math.round(root.inDuration * 0.6); easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root.squish; property: root.vertical ? "yScale" : "xScale"
                to: 1.0; duration: Math.round(root.inDuration * 0.4); easing.type: Easing.InOutQuad
            }
        }
        NumberAnimation {
            target: root.squish; property: root.vertical ? "xScale" : "yScale"
            to: 1.0; duration: root.inDuration; easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: emergeOutAnim
        NumberAnimation { target: root.off; property: "x"; to: root.offX(false); duration: root.outDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: root.off; property: "y"; to: root.offY(false); duration: root.outDuration; easing.type: Easing.InCubic }
        NumberAnimation {
            target: root.squish; property: root.vertical ? "yScale" : "xScale"
            to: root.squash; duration: root.outDuration; easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: root.squish; property: root.vertical ? "xScale" : "yScale"
            to: root.bulge; duration: root.outDuration; easing.type: Easing.InCubic
        }
    }
}
