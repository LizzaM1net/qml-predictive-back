import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

ApplicationWindow {
    id:      root
    visible: true
    width:   360
    height:  780
    title:   "Predictive Back Demo"

    Material.theme:  Material.Dark
    Material.accent: Material.Purple

    // -----------------------------------------------------------------------
    // Gesture state
    // -----------------------------------------------------------------------
    property int  gestureEdge:     -1   // 0=left, 1=right, -1=none
    property real gestureProgress: 0.0
    property real gestureTouchX:   0.0
    property real gestureTouchY:   0.0
    property real gestureStartX:   0.0  // where the finger first touched the edge
    property real gestureStartY:   0.0
    property bool gestureActive:   false

    Connections {
        target: BackGestureHandler

        function onBackStarted(edge, startX, startY) {
            root.gestureEdge     = edge
            root.gestureProgress = 0
            root.gestureActive   = true
            root.gestureStartX   = startX
            root.gestureStartY   = startY
            root.gestureTouchX   = startX
            root.gestureTouchY   = startY
        }

        function onBackProgressed(progress, x, y, edge) {
            root.gestureProgress = progress
            root.gestureTouchX   = x
            root.gestureTouchY   = y
        }

        function onBackCommitted() {
            root.gestureActive   = false
            root.gestureProgress = 0
            successAnim.play()
        }

        function onBackCancelled() {
            root.gestureActive   = false
            root.gestureProgress = 0
            root.gestureEdge     = -1
        }
    }

    // -----------------------------------------------------------------------
    // Background
    // -----------------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0f0c1a" }
            GradientStop { position: 1.0; color: "#1a0d2e" }
        }
    }

    // Subtle grid pattern
    Canvas {
        anchors.fill: parent
        opacity: 0.06
        onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = "#9c27b0"
            ctx.lineWidth   = 0.5
            for (var x = 0; x < width; x += 40) {
                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
            }
            for (var y = 0; y < height; y += 40) {
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
            }
        }
    }

    // -----------------------------------------------------------------------
    // Edge highlights (over everything else except the success overlay)
    // -----------------------------------------------------------------------
    EdgeHighlight {
        visible:  gestureActive && gestureEdge === 0
        edge:     0
        progress: gestureProgress
        touchX:   gestureTouchX
        touchY:   gestureTouchY
        startX:   gestureStartX
        startY:   gestureStartY
        z:        10
    }

    EdgeHighlight {
        visible:  gestureActive && gestureEdge === 1
        edge:     1
        progress: gestureProgress
        touchX:   gestureTouchX
        touchY:   gestureTouchY
        startX:   gestureStartX
        startY:   gestureStartY
        z:        10
    }

    // -----------------------------------------------------------------------
    // Main content
    // -----------------------------------------------------------------------
    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top:              parent.top
            topMargin:        56
        }
        width:   parent.width * 0.84
        spacing: 0

        // Title
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:            "Predictive Back"
            font.pixelSize:  28
            font.bold:       true
            color:           "#e8d5ff"
            bottomPadding:   4
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:            "Android 13+ / API 33+"
            font.pixelSize:  13
            color:           "#7a5f9a"
            bottomPadding:   36
        }

        // ── Exit-to-home switch card ─────────────────────────────────────
        Rectangle {
            width:  parent.width
            height: 72
            radius: 16
            color:  Qt.rgba(0.40, 0.15, 0.65, 0.22)
            border.color: Qt.rgba(0.65, 0.30, 1.0, 0.35)
            border.width: 1

            Row {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left:  parent.left;  leftMargin:  20
                    right: parent.right; rightMargin: 12
                }
                spacing: 0

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - exitSwitch.width - 8
                    Text {
                        text:           "Exit to home"
                        font.pixelSize: 16
                        font.bold:      true
                        color:          "#e0ceff"
                    }
                    Text {
                        text:           exitSwitch.checked
                                            ? "Back gesture closes the app"
                                            : "App handles back itself"
                        font.pixelSize: 12
                        color:          "#9070b8"
                    }
                }

                Switch {
                    id:        exitSwitch
                    checked:   true
                    Material.accent: Material.Purple
                    onCheckedChanged: BackGestureHandler.exitOnBack = checked
                }
            }
        }

        Item { width: 1; height: 24 }

        // ── Gesture progress card ────────────────────────────────────────
        Rectangle {
            id:      progressCard
            width:   parent.width
            height:  gestureActive ? 148 : 64
            radius:  16
            color:   gestureActive
                         ? Qt.rgba(0.40, 0.15, 0.65, 0.30)
                         : Qt.rgba(0.20, 0.10, 0.35, 0.18)
            border.color: gestureActive
                              ? Qt.rgba(0.65, 0.30, 1.0, 0.60)
                              : Qt.rgba(0.45, 0.20, 0.75, 0.25)
            border.width: 1

            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            Behavior on color  { ColorAnimation  { duration: 200 } }

            Column {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left:  parent.left;  leftMargin:  20
                    right: parent.right; rightMargin: 20
                }
                spacing: 10

                // Always-visible status row
                Row {
                    spacing: 10
                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: gestureActive ? "#bb86fc" : "#44334d"
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity {
                            running: gestureActive
                            loops:   Animation.Infinite
                            NumberAnimation { from: 1; to: 0.3; duration: 500 }
                            NumberAnimation { from: 0.3; to: 1; duration: 500 }
                        }
                    }
                    Text {
                        text:           gestureActive
                                            ? (gestureEdge === 0 ? "← Left" : "→ Right") + " edge gesture"
                                            : "Swipe from an edge to begin"
                        font.pixelSize: 14
                        color:          gestureActive ? "#d0aaff" : "#6a5080"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Details shown only while gesture is active
                Column {
                    visible:  gestureActive
                    width:    parent.width
                    spacing:  8
                    opacity:  gestureActive ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    // Progress bar
                    Item {
                        width:  parent.width
                        height: 6
                        Rectangle {
                            anchors.fill: parent
                            radius:       3
                            color:        Qt.rgba(0.35, 0.15, 0.55, 0.5)
                        }
                        Rectangle {
                            width:  Math.max(6, parent.width * gestureProgress)
                            height: parent.height
                            radius: 3
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#7b2ff7" }
                                GradientStop { position: 1.0; color: "#e040fb" }
                            }
                            Behavior on width { NumberAnimation { duration: 32 } }
                        }
                    }

                    Row {
                        spacing: 16
                        Text {
                            text:           "Progress  " + Math.round(gestureProgress * 100) + "%"
                            font.pixelSize: 13
                            color:          "#c090ee"
                        }
                        Text {
                            text:           "x " + Math.round(gestureTouchX) + "  y " + Math.round(gestureTouchY)
                            font.pixelSize: 13
                            color:          "#8860aa"
                        }
                    }
                }
            }
        }

        Item { width: 1; height: 24 }

        // ── Mode indicator ────────────────────────────────────────────────
        Rectangle {
            width:  parent.width
            height: 52
            radius: 16
            color:  exitSwitch.checked
                        ? Qt.rgba(0.10, 0.30, 0.15, 0.30)
                        : Qt.rgba(0.30, 0.10, 0.45, 0.30)
            border.color: exitSwitch.checked
                              ? Qt.rgba(0.20, 0.75, 0.40, 0.45)
                              : Qt.rgba(0.70, 0.20, 1.00, 0.45)
            border.width: 1

            Behavior on color        { ColorAnimation { duration: 300 } }
            Behavior on border.color { ColorAnimation { duration: 300 } }

            Row {
                anchors.centerIn: parent
                spacing: 10
                Text {
                    text:           exitSwitch.checked ? "🏠" : "🔄"
                    font.pixelSize: 18
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text:           exitSwitch.checked
                                        ? "System exits the app"
                                        : "App processes back"
                    font.pixelSize: 14
                    font.bold:      true
                    color:          exitSwitch.checked ? "#69f0ae" : "#ea80fc"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Item { width: 1; height: 32 }

        // ── How-to hint ───────────────────────────────────────────────────
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width:          parent.width
            wrapMode:       Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text:           "Slowly swipe inward from the left or right edge.\n" +
                            "The gesture highlight and progress will appear.\n" +
                            "Complete the swipe to trigger the back action."
            font.pixelSize: 13
            lineHeight:     1.5
            color:          "#5a4070"
        }
    }

    // -----------------------------------------------------------------------
    // Success overlay (topmost)
    // -----------------------------------------------------------------------
    SuccessAnimation {
        id: successAnim
        z:  20
    }
}
