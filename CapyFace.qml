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

  readonly property url portrait: {
    if (root.soaked) return Qt.resolvedUrl("capy-soaked.png")
    if (root.munching) return Qt.resolvedUrl("capy-munching.png")
    if (root.napping) return Qt.resolvedUrl("capy-napping.png")
    return Qt.resolvedUrl("capy.png")
  }

  Image {
    id: portrait
    anchors.fill: parent
    source: root.portrait
    fillMode: Image.PreserveAspectFit
    smooth: true
    opacity: root.napping ? 0.86 : (root.meh ? 0.88 : 1)
    scale: root.popped ? 1.08 : 1
    transformOrigin: Item.Center
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
    Behavior on opacity { NumberAnimation { duration: 180 } }
  }

  Rectangle {
    visible: root.fried
    anchors.fill: portrait
    radius: root.faceSize * 0.18
    color: "#66C45A28"
  }

  Text {
    visible: root.hyped
    text: "✦"
    color: "#F6D27A"
    font.pixelSize: Math.max(11, root.faceSize * 0.22)
    x: root.width * 0.78
    y: -root.faceSize * 0.04
  }

  Text {
    visible: root.lonely
    text: "..."
    color: "#E8D5B0"
    opacity: 0.7
    font.pixelSize: Math.max(8, root.faceSize * 0.16)
    x: root.width * 0.72
    y: root.height * 0.04
  }
}
