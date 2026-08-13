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
  readonly property bool compact: faceSize < 28

  readonly property url portrait: {
    if (root.soaked) return Qt.resolvedUrl("capy-soaked.png")
    if (root.munching) return Qt.resolvedUrl("capy-munching.png")
    if (root.napping) return Qt.resolvedUrl("capy-napping.png")
    return Qt.resolvedUrl("capy.png")
  }

  readonly property int bobMs: root.hyped ? 520 : (root.napping ? 1700 : 980)
  readonly property real bobAmp: {
    if (root.compact) return 0.5
    if (root.hyped) return 2.4
    if (root.napping) return 1.4
    return 1.3
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
    scale: root.popped ? 1.10 : 1
    opacity: root.napping ? 0.9 : 1
    transformOrigin: Item.Center
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 220 } }

    transform: [
      Translate { id: bob; y: 0 },
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
      Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
    }

    Image {
      anchors.fill: parent
      source: root.slotB
      fillMode: Image.PreserveAspectFit
      smooth: true
      opacity: root.showA ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
    }

    Rectangle {
      visible: root.fried
      anchors.fill: parent
      radius: root.faceSize * 0.18
      color: "#C45A28"
      opacity: 0.18
    }

    Repeater {
      model: root.soaked && !root.compact ? 4 : 0
      delegate: Rectangle {
        required property int index
        width: Math.max(2, root.faceSize * 0.045)
        height: width * 1.6
        radius: width
        color: "#7EC8E3"
        opacity: 0
        x: root.width * (0.22 + index * 0.16)

        SequentialAnimation on y {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 160 }
          NumberAnimation { from: root.height * 0.08; to: root.height * 0.9; duration: 900; easing.type: Easing.InCubic }
        }
        SequentialAnimation on opacity {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 160 }
          NumberAnimation { from: 0; to: 0.75; duration: 120 }
          NumberAnimation { from: 0.75; to: 0; duration: 780 }
        }
      }
    }

    Repeater {
      model: root.hyped && !root.compact ? 4 : 0
      delegate: Rectangle {
        required property int index
        width: Math.max(3, root.faceSize * 0.06)
        height: width
        radius: width / 2
        color: "#F6D27A"
        opacity: 0
        x: root.width * (0.16 + index * 0.2)

        SequentialAnimation on opacity {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 140 }
          NumberAnimation { from: 0; to: 0.9; duration: 160 }
          NumberAnimation { from: 0.9; to: 0; duration: 400 }
        }
        SequentialAnimation on y {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 140 }
          NumberAnimation { from: root.height * 0.2; to: -root.faceSize * 0.08; duration: 560; easing.type: Easing.OutCubic }
        }
      }
    }

    Repeater {
      model: root.napping && !root.compact ? 2 : 0
      delegate: Text {
        required property int index
        text: "z"
        color: "#E8D5B0"
        font.pixelSize: Math.max(9, root.faceSize * (0.16 + index * 0.05))
        font.bold: true
        opacity: 0
        x: root.width * 0.74

        SequentialAnimation on opacity {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 320 }
          NumberAnimation { from: 0; to: 0.8; duration: 220 }
          NumberAnimation { from: 0.8; to: 0; duration: 700 }
        }
        SequentialAnimation on y {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 320 }
          NumberAnimation { from: root.height * 0.1; to: -root.faceSize * 0.16; duration: 980; easing.type: Easing.OutCubic }
        }
      }
    }
  }

  SequentialAnimation {
    running: true
    loops: Animation.Infinite
    NumberAnimation { target: bob; property: "y"; to: -root.bobAmp; duration: root.bobMs; easing.type: Easing.InOutSine }
    NumberAnimation { target: bob; property: "y"; to: root.bobAmp; duration: root.bobMs; easing.type: Easing.InOutSine }
  }

  SequentialAnimation {
    running: !root.compact && !root.napping && !root.munching
    loops: Animation.Infinite
    PauseAnimation { duration: 3800 }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 0.9; duration: 70 }
      NumberAnimation { target: squash; property: "xScale"; to: 1.04; duration: 70 }
    }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 1; duration: 90; easing.type: Easing.OutCubic }
      NumberAnimation { target: squash; property: "xScale"; to: 1; duration: 90; easing.type: Easing.OutCubic }
    }
  }

  SequentialAnimation {
    running: root.munching && !root.compact
    loops: Animation.Infinite
    NumberAnimation { target: squash; property: "yScale"; to: 0.92; duration: 140 }
    NumberAnimation { target: squash; property: "yScale"; to: 1; duration: 160; easing.type: Easing.OutCubic }
  }
}
