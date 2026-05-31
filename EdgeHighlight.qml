import QtQuick

Item {
    id: root
    anchors.fill: parent

    // 0 = left edge, 1 = right edge
    property int  edge:    0
    property real progress: 0.0
    property real touchX:  0.0   // current finger X (dp, same coord space as QML)
    property real touchY:  0.0   // current finger Y
    property real startX:  0.0   // where finger first touched
    property real startY:  0.0

    readonly property bool isLeft: edge === 0

    // ── Gradient glow bar — grows wider as progress increases ────────────────
    Rectangle {
        id: bar
        x:      isLeft ? 0 : parent.width - width
        y:      0
        width:  6 + root.progress * 52
        height: parent.height
        color:  "transparent"

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: isLeft ? 0.0 : 1.0
                color: Qt.rgba(0.60, 0.15, 1.0, 0.80 * root.progress)
            }
            GradientStop {
                position: isLeft ? 1.0 : 0.0
                color:    "transparent"
            }
        }

        // Bright leading-edge line
        Rectangle {
            x:      isLeft ? 0 : parent.width - width
            y:      0
            width:  3
            height: parent.height
            color:  Qt.rgba(0.82, 0.42, 1.0, root.progress)
        }

        Behavior on width { NumberAnimation { duration: 32; easing.type: Easing.OutQuad } }
    }

    // ── Dashed line from gesture-start point to current finger ───────────────
    Canvas {
        id: lineCanvas
        anchors.fill: parent
        visible: root.progress > 0.02

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var alpha = Math.min(1.0, root.progress * 2.0) * 0.80
            if (alpha < 0.02) return

            ctx.beginPath()
            ctx.moveTo(root.startX, root.startY)
            ctx.lineTo(root.touchX, root.touchY)
            ctx.setLineDash([7, 5])
            ctx.strokeStyle = "rgba(195, 105, 255, " + alpha + ")"
            ctx.lineWidth   = 2.0
            ctx.lineCap     = "round"
            ctx.stroke()
        }
    }

    // Repaint canvas whenever any tracked coordinate changes
    onTouchXChanged:   lineCanvas.requestPaint()
    onTouchYChanged:   lineCanvas.requestPaint()
    onStartXChanged:   lineCanvas.requestPaint()
    onStartYChanged:   lineCanvas.requestPaint()
    onProgressChanged: lineCanvas.requestPaint()

    // ── Start-point marker — crosshair ring where the gesture began ──────────
    Item {
        id: startMarker
        visible: root.progress > 0.03
        width:   18
        height:  18
        x:       root.startX - width  * 0.5
        y:       root.startY - height * 0.5

        // Outer ring
        Rectangle {
            anchors.fill: parent
            radius:       width * 0.5
            color:        "transparent"
            border.color: Qt.rgba(0.85, 0.45, 1.0, 0.75 * root.progress)
            border.width: 1.5
        }
        // Horizontal crosshair tick
        Rectangle {
            anchors.centerIn: parent
            width:  parent.width * 0.55
            height: 1.5
            color:  Qt.rgba(0.85, 0.45, 1.0, 0.75 * root.progress)
        }
        // Vertical crosshair tick
        Rectangle {
            anchors.centerIn: parent
            width:  1.5
            height: parent.height * 0.55
            color:  Qt.rgba(0.85, 0.45, 1.0, 0.75 * root.progress)
        }
    }

    // ── Live finger dot — follows the exact touch position ──────────────────
    Item {
        id: fingerDot
        visible: root.progress > 0.01

        readonly property real sz: 22 + root.progress * 14
        width:  sz
        height: sz
        x:      root.touchX - sz * 0.5
        y:      root.touchY - sz * 0.5

        Behavior on x { NumberAnimation { duration: 16; easing.type: Easing.OutQuad } }
        Behavior on y { NumberAnimation { duration: 16; easing.type: Easing.OutQuad } }

        // Outer glow ring
        Rectangle {
            anchors.fill: parent
            radius:       width * 0.5
            color:        "transparent"
            border.color: Qt.rgba(0.82, 0.42, 1.0, 0.70 * root.progress)
            border.width: 2
        }

        // Filled inner circle
        Rectangle {
            anchors.centerIn: parent
            width:   parent.width * 0.48
            height:  width
            radius:  width * 0.5
            color:   Qt.rgba(0.72, 0.28, 1.0, 0.88 * root.progress)
        }

        // Direction arrow chevron
        Text {
            anchors.centerIn: parent
            text:             isLeft ? "›" : "‹"
            font.pixelSize:   14
            color:            Qt.rgba(1, 1, 1, root.progress)
        }
    }

    // ── Progress pill ────────────────────────────────────────────────────────
    Rectangle {
        visible:      root.progress > 0.05
        width:        96
        height:       28
        radius:       14
        color:        Qt.rgba(0.10, 0.05, 0.20, 0.88)
        border.color: Qt.rgba(0.65, 0.25, 1.0, 0.60)
        border.width: 1

        x: isLeft ? bar.width + 14 : parent.width - bar.width - width - 14
        y: root.touchY - height * 0.5

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
