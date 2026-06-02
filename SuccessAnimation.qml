import QtQuick
import QtQuick.Shapes
import QtQuick.Particles

Item {
    id: root
    anchors.fill: parent
    visible:      false

    function play() {
        visible = true
        ps.reset()
        ps.running = true
        burstEmitter.burst(32)
        ring1Anim.restart()
        ring2Anim.restart()
        checkSequence.restart()
    }

    // ── Ring 1 — fast expanding purple burst ─────────────────────────────────
    Rectangle {
        id:     ring1
        anchors.centerIn: parent
        width:  0;  height: width;  radius: width * 0.5
        color:  "transparent"
        border.color: "#bb86fc"
        border.width: 3
        opacity: 1

        ParallelAnimation {
            id: ring1Anim
            NumberAnimation { target: ring1; property: "width";   from: 0; to: 340; duration: 520; easing.type: Easing.OutQuart }
            NumberAnimation { target: ring1; property: "opacity"; from: 1; to: 0;   duration: 520; easing.type: Easing.InCubic }
        }
    }

    // ── Ring 2 — slightly slower teal ring for depth ──────────────────────────
    Rectangle {
        id:     ring2
        anchors.centerIn: parent
        width:  0;  height: width;  radius: width * 0.5
        color:  "transparent"
        border.color: "#03dac6"
        border.width: 2
        opacity: 0

        SequentialAnimation {
            id: ring2Anim
            PauseAnimation { duration: 80 }
            ParallelAnimation {
                NumberAnimation { target: ring2; property: "width";   from: 0;    to: 220; duration: 600; easing.type: Easing.OutQuart }
                NumberAnimation { target: ring2; property: "opacity"; from: 0.85; to: 0;   duration: 600; easing.type: Easing.InCubic }
            }
        }
    }

    // ── Checkmark — drawn on via strokeDashOffset animation ──────────────────
    // Path: (5,30) → (27,55) → (75,5)
    // Segment lengths: √(22²+25²) ≈ 33  +  √(48²+50²) ≈ 69  = 102 total
    // Using pattern [105,105] so the gap covers the full path when offset=105,
    // and the stroke covers it completely when offset=0.
    Shape {
        id:      checkShape
        width:   80;  height: 60
        anchors.centerIn: parent
        opacity: 0
        scale:   0.3
        layer.enabled: true     // rasterise to texture for smooth scale animation

        ShapePath {
            id:          checkPath
            strokeColor: "#bb86fc"
            strokeWidth: 6
            fillColor:   "transparent"
            capStyle:    ShapePath.RoundCap
            joinStyle:   ShapePath.RoundJoin

            strokeDashPattern: [105, 105]
            strokeDashOffset:  105          // fully hidden at start

            startX: 5;  startY: 30
            PathLine { x: 27; y: 55 }
            PathLine { x: 75; y: 5  }
        }

        SequentialAnimation {
            id: checkSequence

            // 1. Pop in with an overshoot spring
            PauseAnimation { duration: 120 }
            ParallelAnimation {
                NumberAnimation { target: checkShape; property: "opacity"; from: 0;   to: 1.0; duration: 100 }
                NumberAnimation { target: checkShape; property: "scale";   from: 0.3; to: 1.0; duration: 320; easing.type: Easing.OutBack }
            }

            // 2. Draw the stroke left-to-right
            NumberAnimation {
                target: checkPath; property: "strokeDashOffset"
                from: 105; to: 0; duration: 360; easing.type: Easing.OutCubic
            }

            // 3. Hold
            PauseAnimation { duration: 620 }

            // 4. Fade and shrink out
            ParallelAnimation {
                NumberAnimation { target: checkShape; property: "opacity"; from: 1; to: 0; duration: 260 }
                NumberAnimation { target: checkShape; property: "scale"; from: 1.0; to: 0.7; duration: 260; easing.type: Easing.InCubic }
            }

            ScriptAction { script: { root.visible = false; ps.running = false } }
        }
    }

    // ── Particle burst ────────────────────────────────────────────────────────
    ParticleSystem {
        id: ps
        anchors.centerIn: parent
        running: false

        Emitter {
            id:    burstEmitter
            emitRate: 0
            lifeSpan:          900
            lifeSpanVariation: 300
            size: 10;  sizeVariation: 6

            velocity: AngleDirection {
                angleVariation:     360
                magnitude:          170
                magnitudeVariation: 90
            }
            // Gravity pulls particles down so they arc naturally
            acceleration: PointDirection { y: 240 }
        }

        // Each particle is a small coloured circle Item.
        // Math.random() in the delegate is evaluated fresh per instance, giving
        // varied sizes and hues across the burst without any manual loop.
        ItemParticle {
            delegate: Rectangle {
                readonly property real sz: 7 + Math.random() * 9
                width:  sz;  height: sz;  radius: sz * 0.5
                color:  Qt.hsla((248 + Math.random() * 92) / 360, 0.90, 0.65, 1.0)
            }
        }
    }
}
