import QtQuick
import QtQuick.Shapes

// A quarter "inverse fillet": fills an r x r square MINUS a quarter disk,
// producing a concave curve. Used where the frame meets the workspace area
// and where panels attach to the frame.
//
// `corner` names where the right angle of the wedge points — i.e. which
// corner of the r x r box stays solid. No internal layers here: consumers
// sit near input-masked windows and a layered item would break their masks.
Shape {
    id: root

    // topLeft | topRight | bottomLeft | bottomRight
    property string corner: "topLeft"
    property real radius: 12
    property alias color: p.fillColor
    property alias strokeColor: p.strokeColor
    property alias strokeWidth: p.strokeWidth

    implicitWidth: radius
    implicitHeight: radius
    preferredRendererType: Shape.CurveRenderer

    // One canonical topLeft path; other corners are 90-degree rotations, which
    // keep the axis-aligned edges pixel-exact.
    rotation: ({ topLeft: 0, topRight: 90, bottomRight: 180, bottomLeft: 270 })[corner] ?? 0

    ShapePath {
        id: p

        strokeWidth: -1
        fillColor: "black"

        // Wedge with its right angle at (0,0); quarter disk centered at (r,r).
        startX: 0; startY: root.radius
        PathLine { x: 0; y: 0 }
        PathLine { x: root.radius; y: 0 }
        // Arc (r,0) -> (0,r) on the circle centered (r,r), bulging toward (0,0)
        PathArc {
            x: 0; y: root.radius
            radiusX: root.radius; radiusY: root.radius
            direction: PathArc.Counterclockwise
        }
    }
}
