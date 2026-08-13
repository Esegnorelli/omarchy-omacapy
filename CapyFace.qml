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
    if (root.napping) return 1700
    if (root.hyped) return 520
    if (root.fried) return 640
    return 980
  }

  readonly property real bobAmp: {
    if (root.compact) return root.hyped ? 1.2 : 0.6
    if (root.napping) return 1.4
    if (root.hyped) return 2.4
    if (root.fried) return 1.8
    return 1.2
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
    scale: root.popped ? 1.07 : 1
    opacity: root.napping ? 0.9 : (root.meh ? 0.88 : 1)
    transformOrigin: Item.Center
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 280 } }

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
        NumberAnimation { from: 0.10; to: 0.28; duration: 420; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.28; to: 0.10; duration: 420; easing.type: Easing.InOutSine }
      }
    }

    Repeater {
      model: root.soaked && !root.compact ? 4 : 0
      delegate: Rectangle {
        required property int index
        width: Math.max(2, root.faceSize * 0.045)
        height: width * 1.7
        radius: width
        color: "#7EC8E3"
        opacity: 0
        x: root.width * (0.22 + index * 0.16)
        y: 0

        SequentialAnimation on y {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 160 }
          NumberAnimation { from: root.height * 0.08; to: root.height * 0.92; duration: 980; easing.type: Easing.InCubic }
        }
        SequentialAnimation on opacity {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 160 }
          NumberAnimation { from: 0; to: 0.8; duration: 140 }
          NumberAnimation { from: 0.8; to: 0; duration: 840 }
        }
      }
    }

    Repeater {
      model: root.hyped && !root.compact ? 3 : 0
      delegate: Rectangle {
        required property int index
        width: Math.max(3, root.faceSize * 0.07)
        height: width
        radius: width / 2
        color: "#F6D27A"
        opacity: 0.0
        x: root.width * (0.12 + index * 0.32)
        y: root.height * 0.08

        SequentialAnimation on opacity {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 120 }
          NumberAnimation { from: 0; to: 0.9; duration: 180 }
          NumberAnimation { from: 0.9; to: 0; duration: 420 }
        }
        SequentialAnimation on y {
          running: true
          loops: Animation.Infinite
          PauseAnimation { duration: index * 120 }
          NumberAnimation { from: root.height * 0.18; to: -root.faceSize * 0.08; duration: 600; easing.type: Easing.OutCubic }
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
    running: !root.napping
    loops: Animation.Infinite
    PauseAnimation { duration: root.hyped ? 2200 : 4600 }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 0.88; duration: 70 }
      NumberAnimation { target: squash; property: "xScale"; to: 1.04; duration: 70 }
    }
    ParallelAnimation {
      NumberAnimation { target: squash; property: "yScale"; to: 1; duration: 90; easing.type: Easing.OutCubic }
      NumberAnimation { target: squash; property: "xScale"; to: 1; duration: 90; easing.type: Easing.OutCubic }
    }
  }
}
