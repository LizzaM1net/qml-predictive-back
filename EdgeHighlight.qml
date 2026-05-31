import QtQuick

Item {
    id: root

    // 0 = left edge, 1 = right edge
    property int  edge:     0
    property real progress: 0.0
    property real touchY:   0.0

    anchors.fill: parent

    readonly property bool isLeft: edge === 0

    // Glow bar — grows wider as progress increases
    Rectangle {
        id: bar
        x:      isLeft ? 0 : parent.width - width
        y:      0
        width:  6 + root.progress * 48
        height: parent.height
        color:  "transparent"

        // Purple gradient fading inward
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: isLeft ? 0.0 : 1.0
                color: Qt.rgba(0.60, 0.15, 1.0, 0.85 * root.progress)
            }
            GradientStop {
                position: isLeft ? 1.0 : 0.0
                color:    "transparent"
            }
        }

        // Bright leading edge line
        Rectangle {
            x:      isLeft ? 0 : parent.width - width
            y:      0
            width:  3
            height: parent.height
            color:  Qt.rgba(0.80, 0.40, 1.0, root.progress)

            layer.enabled: true
            layer.effect: null   // replaced at runtime if QtGraphicalEffects available
        }

        Behavior on width { NumberAnimation { duration: 32; easing.type: Easing.OutQuad } }
    }

    // Touch-point orb
    Item {
        id: orb
        width:  56 + root.progress * 24
        height: width
        x:      isLeft
                    ? bar.width - width * 0.45
                    : parent.width - bar.width - width * 0.55
        y:      root.touchY - height * 0.5

        Behavior on x      { NumberAnimation { duration: 32 } }
        Behavior on y      { NumberAnimation { duration: 16 } }
        Behavior on width  { NumberAnimation { duration: 32 } }

        // Outer ring
        Rectangle {
            anchors.fill: parent
            radius:       width * 0.5
            color:        "transparent"
            border.color: Qt.rgba(0.75, 0.35, 1.0, 0.7 * root.progress)
            border.width: 2
        }

        // Inner fill
        Rectangle {
            anchors.centerIn: parent
            width:   parent.width * 0.55
            height:  width
            radius:  width * 0.5
            color:   Qt.rgba(0.65, 0.25, 1.0, 0.45 * root.progress)
        }

        // Arrow chevron
        Text {
            anchors.centerIn: parent
            text:             isLeft ? "›" : "‹"
            font.pixelSize:   20
            color:            Qt.rgba(1, 1, 1, root.progress)
        }
    }

    // Progress pill — shown near the orb
    Rectangle {
        visible:      root.progress > 0.05
        width:        96
        height:       28
        radius:       14
        color:        Qt.rgba(0.12, 0.06, 0.22, 0.88)
        border.color: Qt.rgba(0.65, 0.25, 1.0, 0.6)
        border.width: 1

        x: isLeft ? bar.width + 12 : parent.width - bar.width - width - 12
        y: root.touchY - height * 0.5

        Behavior on x { NumberAnimation { duration: 32 } }
        Behavior on y { NumberAnimation { duration: 16 } }

        Text {
            anchors.centerIn: parent
            text:             Math.round(root.progress * 100) + "%"
            color:            "#d0a0ff"
            font.pixelSize:   13
            font.bold:        true
        }
    }
}
