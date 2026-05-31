import QtQuick

Item {
    id: root
    anchors.fill: parent
    visible:      false

    function play() {
        visible = true
        ringAnim.restart()
        checkAnim.restart()
        particleCanvas.launch()
    }

    // Expanding ring burst
    Rectangle {
        id: ring
        anchors.centerIn: parent
        width:   0
        height:  width
        radius:  width * 0.5
        color:   "transparent"
        border.color: "#bb86fc"
        border.width: 3
        opacity: 1.0

        ParallelAnimation {
            id: ringAnim
            NumberAnimation { target: ring; property: "width";   from: 0; to: 340; duration: 520; easing.type: Easing.OutQuart }
            NumberAnimation { target: ring; property: "opacity"; from: 1; to: 0;   duration: 520; easing.type: Easing.InCubic }
        }
    }

    // Second, slightly delayed ring for depth
    Rectangle {
        anchors.centerIn: parent
        width:   0
        height:  width
        radius:  width * 0.5
        color:   "transparent"
        border.color: "#03dac6"
        border.width: 2
        opacity: 1.0

        ParallelAnimation {
            id: ring2Anim
            running: false
            NumberAnimation { target: parent; property: "width";   from: 0; to: 220; duration: 600; delay: 80; easing.type: Easing.OutQuart }
            NumberAnimation { target: parent; property: "opacity"; from: 0.85; to: 0; duration: 600; delay: 80; easing.type: Easing.InCubic }
        }
    }

    // Checkmark
    Text {
        id: check
        anchors.centerIn: parent
        text:             "✓"
        color:            "#bb86fc"
        font.pixelSize:   checkSize
        opacity:          0.0

        property real checkSize: 0

        SequentialAnimation {
            id: checkAnim
            NumberAnimation { target: check; property: "checkSize"; from: 0; to: 88; duration: 380; easing.type: Easing.OutBack }
            NumberAnimation { target: check; property: "opacity";   from: 0; to: 1;  duration: 180 }
            PauseAnimation  { duration: 700 }
            NumberAnimation { target: check; property: "opacity";   from: 1; to: 0;  duration: 260 }
            ScriptAction    { script: { root.visible = false } }
        }
    }

    // Canvas-based particles
    Canvas {
        id: particleCanvas
        anchors.fill: parent

        property var particles: []

        function launch() {
            ring2Anim.restart()
            var cx = width  * 0.5
            var cy = height * 0.5
            particles = []
            for (var i = 0; i < 28; i++) {
                var angle = Math.random() * Math.PI * 2
                var speed = 3.5 + Math.random() * 5.5
                particles.push({
                    x:    cx, y: cy,
                    vx:   Math.cos(angle) * speed,
                    vy:   Math.sin(angle) * speed,
                    r:    3 + Math.random() * 5,
                    hue:  Math.floor(250 + Math.random() * 80),
                    life: 1.0,
                    fade: 0.018 + Math.random() * 0.012
                })
            }
            particleTimer.start()
        }

        Timer {
            id: particleTimer
            interval: 16
            repeat:   true
            onTriggered: {
                var alive = []
                for (var i = 0; i < particleCanvas.particles.length; i++) {
                    var p = particleCanvas.particles[i]
                    p.x   += p.vx * 2.4
                    p.y   += p.vy * 2.4
                    p.vy  += 0.18   // gravity
                    p.life -= p.fade
                    if (p.life > 0) alive.push(p)
                }
                particleCanvas.particles = alive
                if (alive.length === 0) particleTimer.stop()
                particleCanvas.requestPaint()
            }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var ps = particles
            for (var i = 0; i < ps.length; i++) {
                var p = ps[i]
                ctx.beginPath()
                ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2)
                ctx.fillStyle = "hsla(" + p.hue + ",85%,65%," + p.life + ")"
                ctx.shadowBlur  = 8
                ctx.shadowColor = "hsla(" + p.hue + ",90%,70%,0.6)"
                ctx.fill()
            }
        }
    }
}
