pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// MD3 outlined text field. The label sits above rather than floating, which
// keeps a column of these aligned when several stack up in a form.
Item {
    id: root

    property string label: ""
    property string placeholder: ""
    property alias text: input.text
    property bool enabled: true
    property bool invalid: false

    signal accepted()

    implicitHeight: labelText.implicitHeight + 6 + 44
    implicitWidth: 260

    Text {
        id: labelText
        anchors { top: parent.top; left: parent.left; right: parent.right }
        text: root.label
        color: root.invalid ? Md.error : Md.textOnSurfaceVariant
        font.family: Md.fontFamily
        font.pixelSize: Md.labelSmall
        font.weight: Font.Medium

        Behavior on color { ColorAnimation { duration: Md.durShort } }
    }

    Rectangle {
        anchors {
            top: labelText.bottom
            topMargin: 6
            left: parent.left
            right: parent.right
        }
        height: 44
        radius: Md.cornerS
        color: root.enabled ? Md.surfaceContainerHighest : Md.surfaceContainer
        border.width: input.activeFocus || root.invalid ? 2 : 1
        border.color: root.invalid ? Md.error
            : input.activeFocus ? Md.primary
            : Md.outlineVariant
        opacity: root.enabled ? 1 : Md.disabledOpacity

        Behavior on border.color { ColorAnimation { duration: Md.durShort } }
        Behavior on opacity { NumberAnimation { duration: Md.durMedium } }

        TextInput {
            id: input
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            verticalAlignment: TextInput.AlignVCenter
            color: Md.textOnSurface
            // Monospace: these are addresses, and digits need to line up
            font.family: Md.iconFamily
            font.pixelSize: Md.bodyMedium
            selectByMouse: true
            selectionColor: Md.primary
            selectedTextColor: Md.textOnPrimary
            enabled: root.enabled
            clip: true

            onAccepted: root.accepted()

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: root.placeholder
                color: Md.textOnSurfaceVariant
                font: input.font
                visible: input.text.length === 0
                opacity: 0.7
            }
        }
    }
}
