import QtQuick

Item {
  id: root

  property string mood: "chill"
  property bool popped: false
  property real faceSize: 64

  width: faceSize
  height: faceSize * 1.08

  readonly property bool napping: mood === "napping"
  readonly property bool soaked: mood === "soaked"
  readonly property bool munching: mood === "munching"
  readonly property bool hyped: mood === "hyped"
  readonly property bool fried: mood === "fried"
  readonly property bool lonely: mood === "lonely"
  readonly property bool meh: mood === "meh"
  readonly property bool compact: faceSize < 28

  readonly property url portrait: {
    if (root.soaked) return Qt.resolvedUrl("capy-soaked.png")
    if (root.munching) return Qt.resolvedUrl("capy-munching.png")
    if (root.napping) return Qt.resolvedUrl("capy-napping.png")
    return Qt.resolvedUrl("capy.png")
  }

  readonly property int bobMs: {
    if (root.napping) return 1800
    if (root.hyped) return 420
    if (root.fried) return 560
    if (root.lonely) return 1400
    if (root.meh) return 1600
    return 860
  }

  readonly property real bobAmp: {
    if (root.compact) return root.hyped ? 1.6 : 0.9
    if (root.napping) return 2.2
    if (root.hyped) return 3.4
    if (root.fried) return 2.6
    if (root.lonely) return 2.0
    if (root.meh) return 0.8
    return 1.8
  }

  readonly property real swayAmp: {
    if (root.compact) return root.hyped ? 0.8 : 0.3
    if (root.lonely) return 2.4
    if (root.hyped) return 2.2
    if (root.fried) return 1.6
    return 0.9
  }

  readonly property real tiltAmp: {
    if (root.compact) return root.hyped ? 4 : 1.5
    if (root.lonely) return 7
    if (root.hyped) return 8
    if (root.fried) return 5
    if (root.meh) return 3
    return 2.5
  }

  property url slotA: Qt.resolvedUrl("capy.png")
  property url slotB: Qt.resolvedUrl("capy.png")
  property bool showA: true

  onPortraitChanged: {
    if (root.showA) {
      if (root.slotA === root.portrait) return
      root.slotB = root.portrait
      root.showA = false
    } else {
      if (root.slotB === root.portrait) return
      root.slotA = root.portrait
      root.showA = true
    }
  }

  Component.onCompleted: {
    slotA = portrait
    showA = true
  }

  Item {
    id: stage
    anchors.fill: parent
    scale: root.popped ? 1.16 : 1
    opacity: root.napping ? 0.92 : (root.meh ? 0.84 : 1)
    transformOrigin: Item.Center
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
    Behavior on opacity { NumberAnimation { duration: 280 } }

    transform: [
      Translate { id: bob; y: 0 },
      Translate { id: sway; x: 0 },
      Rotation {
        id: tilt
        origin.x: stage.width / 2
        origin.y: stage.height / 2
        angle: 0
      },
      Scale {
        id: squash
        origin.x: stage.width / 2
        origin.y: stage.height / 2
        xScale: 1
        yScale: 1
      }
    ]

    Image {
      anchors.fill: parent
      source: root.slotA
      fillMode: Image.PreserveAspectFit
      smooth: true
      opacity: root.showA ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
    }

    Image {
      anchors.fill: parent
      source: root.slotB
      fillMode: Image.PreserveAspectFit
      smooth: true
      opacity: root.showA ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
    }

    Rectangle {
      visible: root.fried
      anchors.fill: parent
      radius: root.faceSize * 0.18
      color: "#C45A28"
      opacity: 0.16

      SequentialAnimation on opacity {
        running: root.fried
        loops: Animation.Infinite
        NumberAnimation { from: 0.10; to: 0.38; duration: 280; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.38; to: 0.10; duration: 280; easing.type: Easing.InOutSine }
      }
    }

    Rectangle {
      visible: root.soaked && !root.compact
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      width: parent.width * 0.62
      height: Math.max(4, root.faceSize * 0.10)
      radius: height / 2
      color: "#7EC8E3"
      opacity: 0.28

      SequentialAnimation on scale {
        running: root.soaked && !root.compact
        loops: Animation.Infinite
        NumberAnimation { from: 0.86; to: 1.12; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.12; to: 0.86; duration: 900; easing.type: Easing.InOutSine }
      }
    }

    Repeater {
      model: root.soaked ? (root.compact ? 2 : 7) : 0
      delegate: Rectangle {
        required property int index
        width: Math.max(2, root.faceSize * 0.05)
        height: width * 1.7
        radius: width
        color: "#7EC8E3"
        opacity: 0
        x: root.width * (0.14 + (index % 5) * 0.15)
        y: 0

        SequentialAnimation on y {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 110 }
          NumberAnimation { from: root.height * 0.04; to: root.height * 0.96; duration: 780; easing.type: Easing.InCubic }
        }
        SequentialAnimation on opacity {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 110 }
          NumberAnimation { from: 0; to: 0.9; duration: 120 }
          NumberAnimation { from: 0.9; to: 0; duration: 660 }
        }
      }
    }

    Repeater {
      model: (root.hyped || root.popped) ? (root.compact ? 3 : 8) : 0
      delegate: Rectangle {
        required property int index
        width: Math.max(3, root.faceSize * (0.055 + (index % 3) * 0.02))
        height: width
        radius: width / 2
        color: index % 2 === 0 ? "#F6D27A" : "#E39B2B"
        opacity: 0.0
        x: root.width * (0.08 + (index % 4) * 0.24)
        y: root.height * 0.08

        SequentialAnimation on opacity {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 90 }
          NumberAnimation { from: 0; to: 1; duration: 140 }
          NumberAnimation { from: 1; to: 0; duration: 380 }
        }
        SequentialAnimation on y {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 90 }
          NumberAnimation { from: root.height * 0.22; to: -root.faceSize * 0.18; duration: 520; easing.type: Easing.OutCubic }
        }
        SequentialAnimation on x {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 90 }
          NumberAnimation {
            from: root.width * (0.08 + (index % 4) * 0.24)
            to: root.width * (0.08 + (index % 4) * 0.24) + (index % 2 === 0 ? 10 : -10)
            duration: 520
          }
        }
      }
    }

    Repeater {
      model: root.napping && !root.compact ? 3 : 0
      delegate: Text {
        required property int index
        text: "z"
        color: "#E8D5B0"
        font.pixelSize: Math.max(8, root.faceSize * (0.16 + index * 0.05))
        font.bold: true
        opacity: 0
        x: root.width * 0.72
        y: root.height * 0.08

        SequentialAnimation on opacity {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 280 }
          NumberAnimation { from: 0; to: 0.85; duration: 220 }
          NumberAnimation { from: 0.85; to: 0; duration: 700 }
        }
        SequentialAnimation on y {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 280 }
          NumberAnimation { from: root.height * 0.12; to: -root.faceSize * 0.22; duration: 920; easing.type: Easing.OutCubic }
        }
        SequentialAnimation on x {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 280 }
          NumberAnimation { from: root.width * 0.68; to: root.width * 0.92; duration: 920 }
        }
      }
    }

    Repeater {
      model: root.lonely && !root.compact ? 3 : 0
      delegate: Rectangle {
        required property int index
        width: Math.max(3, root.faceSize * 0.05)
        height: width
        radius: width / 2
        color: "#E8D5B0"
        opacity: 0
        x: root.width * 0.78 + index * 5
        y: root.height * 0.12

        SequentialAnimation on opacity {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: 400 + index * 220 }
          NumberAnimation { from: 0; to: 0.7; duration: 180 }
          PauseAnimation { duration: 160 }
          NumberAnimation { from: 0.7; to: 0; duration: 220 }
        }
      }
    }
  }

  SequentialAnimation {
    running: true
    loops: Animation.Infinite
    NumberAnimation {
      target: bob
      property: "y"
      to: -root.bobAmp
      duration: root.bobMs
      easing.type: Easing.InOutSine
    }
    NumberAnimation {
      target: bob
      property: "y"
      to: root.bobAmp
      duration: root.bobMs
      easing.type: Easing.InOutSine
    }
  }

  SequentialAnimation {
    running: true
    loops: Animation.Infinite
    NumberAnimation {
      target: sway
      property: "x"
      to: root.swayAmp
      duration: root.bobMs + 180
      easing.type: Easing.InOutSine
    }
    NumberAnimation {
      target: sway
      property: "x"
      to: -root.swayAmp
      duration: root.bobMs + 180
      easing.type: Easing.InOutSine
    }
  }

  SequentialAnimation {
    running: true
    loops: Animation.Infinite
    NumberAnimation {
      target: tilt
      property: "angle"
      to: root.tiltAmp
      duration: root.bobMs + 80
      easing.type: Easing.InOutSine
    }
    NumberAnimation {
      target: tilt
      property: "angle"
      to: -root.tiltAmp
      duration: root.bobMs + 80
      easing.type: Easing.InOutSine
    }
  }

  SequentialAnimation {
    running: !root.napping && !root.munching
    loops: Animation.Infinite
    PauseAnimation { duration: root.hyped ? 1600 : 3400 }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 0.84; duration: 60 }
      NumberAnimation { target: squash; property: "xScale"; to: 1.08; duration: 60 }
    }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 1; duration: 90; easing.type: Easing.OutBack }
      NumberAnimation { target: squash; property: "xScale"; to: 1; duration: 90; easing.type: Easing.OutBack }
    }
    PauseAnimation { duration: root.hyped ? 180 : 420 }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 0.88; duration: 50 }
      NumberAnimation { target: squash; property: "xScale"; to: 1.05; duration: 50 }
    }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 1; duration: 80; easing.type: Easing.OutCubic }
      NumberAnimation { target: squash; property: "xScale"; to: 1; duration: 80; easing.type: Easing.OutCubic }
    }
  }

  SequentialAnimation {
    running: root.munching
    loops: Animation.Infinite
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 0.90; duration: 120 }
      NumberAnimation { target: squash; property: "xScale"; to: 1.06; duration: 120 }
    }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 1.05; duration: 140; easing.type: Easing.OutCubic }
      NumberAnimation { target: squash; property: "xScale"; to: 0.96; duration: 140; easing.type: Easing.OutCubic }
    }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 1; duration: 110 }
      NumberAnimation { target: squash; property: "xScale"; to: 1; duration: 110 }
    }
  }
}
