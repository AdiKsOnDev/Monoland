pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// MD3 filled card. Children go into a padded column; an optional `title`
// renders as the MD3 section label above them.
Rectangle {
    id: root

    property int padding: 8
    property string title: ""

    default property alias content: column.data

    readonly property bool titled: title !== ""
    // Space above/below the title label when there is one
    readonly property int headerTop: 14
    readonly property int headerGap: 10

    color: Md.surfaceContainerLow
    radius: Md.cornerL
    implicitWidth: 320
    // Derived from the header's implicitHeight, never its height — binding the
    // Text's height back to its own implicitHeight loops.
    implicitHeight: (titled ? headerTop + header.implicitHeight + headerGap : padding)
        + column.implicitHeight + padding

    Behavior on color { ColorAnimation { duration: Md.durMedium } }

    Text {
        id: header
        visible: root.titled
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: root.headerTop
            leftMargin: root.padding + 8
            rightMargin: root.padding + 8
        }
        text: root.title
        color: Md.textOnSurfaceVariant
        font.family: Md.fontFamily
        font.pixelSize: Md.labelMedium
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    Column {
        id: column
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: root.padding
            rightMargin: root.padding
            topMargin: root.titled
                ? root.headerTop + header.implicitHeight + root.headerGap
                : root.padding
        }
        spacing: 2
    }
}
