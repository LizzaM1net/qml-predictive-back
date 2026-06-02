import QtQuick

Item {
    id: root
    anchors.fill: parent
    visible: false

    function play() {
        visible = true
        ring1Anim.restart()
        ring2Anim.restart()
        for (var i = 0; i < particleRep.count; i++)
            particleRep.itemAt(i).go()
        checkSequence.restart()
    }

    // ── Ring 1 — fast purple burst ────────────────────────────────────────────
    Rectangle {
        id:     ring1
        anchors.centerIn: parent
        width:  0;  height: width;  radius: width * 0.5
        color:  "transparent"
        border.color: "#bb86fc"
        border.width: 3
        opacity: 1.0

        ParallelAnimation {
            id: ring1Anim
            NumberAnimation { target: ring1; property: "width";   from: 0; to: 340; duration: 520; easing.type: Easing.OutQuart }
            NumberAnimation { target: ring1; property: "opacity"; from: 1; to: 0;   duration: 520; easing.type: Easing.InCubic }
        }
    }

    // ── Ring 2 — slower teal ring for depth ───────────────────────────────────
    Rectangle {
        id:     ring2
        anchors.centerIn: parent
        width:  0;  height: width;  radius: width * 0.5
        color:  "transparent"
        border.color: "#03dac6"
        border.width: 2
        opacity: 0.0

        SequentialAnimation {
            id: ring2Anim
            PauseAnimation { duration: 80 }
            ParallelAnimation {
                NumberAnimation { target: ring2; property: "width";   from: 0;    to: 220; duration: 600; easing.type: Easing.OutQuart }
                NumberAnimation { target: ring2; property: "opacity"; from: 0.85; to: 0;   duration: 600; easing.type: Easing.InCubic }
            }
        }
    }

    // ── Checkmark — two rotated Rectangles grown from their left pivot ─────────
    // Layout (in checkGroup's 80×60 space):
    //   short arm  pivot=(5,30)  rotation=49°  length=34
    //   long  arm  pivot=(27,55) rotation=-46° length=70
    // Arm grows from the pivot outward because transformOrigin=Item.Left keeps
    // the left-center edge fixed while width expands to the right.
    Item {
        id: checkGroup
        anchors.centerIn: parent
        width: 80;  height: 60
        opacity: 0.0
        scale:   0.3

        Rectangle {
            id: shortArm
            x: 5;  y: 27.5          // left-center of rect sits at (5, 30) in parent
            width: 0;  height: 5;  radius: 2.5
            color: "#bb86fc"
            transformOrigin: Item.Left
            rotation: 49
        }

        Rectangle {
            id: longArm
            x: 27;  y: 52.5         // left-center of rect sits at (27, 55) in parent
            width: 0;  height: 5;  radius: 2.5
            color: "#bb86fc"
            transformOrigin: Item.Left
            rotation: -46
        }

        SequentialAnimation {
            id: checkSequence

            // Pop in with spring overshoot
            PauseAnimation  { duration: 120 }
            ParallelAnimation {
                NumberAnimation { target: checkGroup; property: "opacity"; from: 0;   to: 1.0; duration: 100 }
                NumberAnimation { target: checkGroup; property: "scale";   from: 0.3; to: 1.0; duration: 320; easing.type: Easing.OutBack }
            }

            // Draw short arm then long arm
            NumberAnimation { target: shortArm; property: "width"; from: 0; to: 34; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: longArm;  property: "width"; from: 0; to: 70; duration: 300; easing.type: Easing.OutCubic }

            // Hold
            PauseAnimation { duration: 620 }

            // Shrink and fade out
            ParallelAnimation {
                NumberAnimation { target: checkGroup; property: "opacity"; from: 1.0; to: 0; duration: 260 }
                NumberAnimation { target: checkGroup; property: "scale";   from: 1.0; to: 0.7; duration: 260; easing.type: Easing.InCubic }
            }
            ScriptAction { script: root.visible = false }
        }
    }

    // ── Particle burst — 24 coloured dots, pure QML NumberAnimation ───────────
    // Dots fan out in evenly-spaced angles with slight speed variation.
    // Each dot exposes go() so play() can restart all of them in one loop.
    Repeater {
        id: particleRep
        model: 24

        Item {
            id: dot

            readonly property real angle:   (index / 24.0) * Math.PI * 2
            readonly property real dist:    90 + (index % 6) * 20
            readonly property real dotSize: 7  + (index % 4) * 2.5

            // Start centred; go() resets via explicit `from` before animating
            x: root.width  / 2 - dotSize / 2
            y: root.height / 2 - dotSize / 2
            width: dotSize;  height: dotSize
            opacity: 0

            Rectangle {
                anchors.fill: parent
                radius: parent.width / 2
                color:  Qt.hsla(((248 + index * 14) % 360) / 360, 0.90, 0.65, 1.0)
            }

            function go() { dotAnim.restart() }

            ParallelAnimation {
                id: dotAnim

                NumberAnimation {
                    target: dot;  property: "x"
                    from: root.width  / 2 - dot.dotSize / 2
                    to:   root.width  / 2 + Math.cos(dot.angle) * dot.dist - dot.dotSize / 2
                    duration: 680 + index * 12
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: dot;  property: "y"
                    // Extra +50 shifts the arc downward like gravity
                    from: root.height / 2 - dot.dotSize / 2
                    to:   root.height / 2 + Math.sin(dot.angle) * dot.dist + 50 - dot.dotSize / 2
                    duration: 680 + index * 12
                    easing.type: Easing.OutCubic
                }
                SequentialAnimation {
                    NumberAnimation { target: dot; property: "opacity"; to: 1;   duration: 70  }
                    NumberAnimation { target: dot; property: "opacity"; to: 0;   duration: 610; easing.type: Easing.InQuad }
                }
            }
        }
    }
}
