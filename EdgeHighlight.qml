import QtQuick

Item {
    id: root
    anchors.fill: parent

    // 0 = left edge, 1 = right edge
    property int  edge:     0
    property real progress: 0.0
    property real touchX:   0.0   // current finger position in QML (dp) coords
    property real touchY:   0.0
    property real startX:   0.0   // where the gesture began
    property real startY:   0.0

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

        // Bright leading-edge accent line
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

    onTouchXChanged:   lineCanvas.requestPaint()
    onTouchYChanged:   lineCanvas.requestPaint()
    onStartXChanged:   lineCanvas.requestPaint()
    onStartYChanged:   lineCanvas.requestPaint()
    onProgressChanged: lineCanvas.requestPaint()

    // ── Start-point crosshair ─────────────────────────────────────────────────
    // A 0×0 anchor container positioned at the exact start coordinates avoids
    // any accidental animation when only the visual size changes.
    Item {
        visible: root.progress > 0.03
        x: root.startX   // positioned at exact start point
        y: root.startY
        width: 0; height: 0

        Rectangle {
            anchors.centerIn: parent
            width:  18; height: 18
            radius: 9
            color:        "transparent"
            border.color: Qt.rgba(0.85, 0.45, 1.0, 0.75 * root.progress)
            border.width: 1.5
        }
        Rectangle {     // horizontal tick
            anchors.centerIn: parent
            width:  10; height: 1.5
            color: Qt.rgba(0.85, 0.45, 1.0, 0.75 * root.progress)
        }
        Rectangle {     // vertical tick
            anchors.centerIn: parent
            width:  1.5; height: 10
            color: Qt.rgba(0.85, 0.45, 1.0, 0.75 * root.progress)
        }
    }

    // ── Live finger dot ───────────────────────────────────────────────────────
    // 0×0 container: only its x/y animate (following the finger). Children are
    // anchored to its center, so their size changes never trigger a position
    // Behavior and never look like movement.
    Item {
        id: fingerAnchor
        visible: root.progress > 0.01
        x: root.touchX    // exact touch position
        y: root.touchY
        width: 0; height: 0

        Behavior on x { NumberAnimation { duration: 16; easing.type: Easing.OutQuad } }
        Behavior on y { NumberAnimation { duration: 16; easing.type: Easing.OutQuad } }

        // Outer glow ring
        Rectangle {
            property real sz: 22 + root.progress * 14
            anchors.centerIn: parent
            width:   sz; height: sz
            radius:  sz * 0.5
            color:   "transparent"
            border.color: Qt.rgba(0.82, 0.42, 1.0, 0.70 * root.progress)
            border.width: 2
        }

        // Filled inner circle
        Rectangle {
            property real sz: (22 + root.progress * 14) * 0.48
            anchors.centerIn: parent
            width:   sz; height: sz
            radius:  sz * 0.5
            color:   Qt.rgba(0.72, 0.28, 1.0, 0.88 * root.progress)
        }

        // Direction arrow
        Text {
            anchors.centerIn: parent
            text:           isLeft ? "›" : "‹"
            font.pixelSize: 14
            color:          Qt.rgba(1, 1, 1, root.progress)
        }
    }

    // ── Progress pill ─────────────────────────────────────────────────────────
    Item {
        visible: root.progress > 0.05
        x: isLeft ? bar.width + 14 : parent.width - bar.width - 14
        y: root.touchY      // follows the finger vertically (no size dependency)
        width: 0; height: 0

        Behavior on y { NumberAnimation { duration: 16 } }

        Rectangle {
            anchors.centerIn: parent
            width:  96; height: 28
            radius: 14
            color:        Qt.rgba(0.10, 0.05, 0.20, 0.88)
            border.color: Qt.rgba(0.65, 0.25, 1.0, 0.60)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text:           Math.round(root.progress * 100) + "%"
                color:          "#d0a0ff"
                font.pixelSize: 13
                font.bold:      true
            }
        }
    }
}
