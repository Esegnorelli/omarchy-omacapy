import QtQuick

// Roommate face: illustrated capy plus tiny mood props.
Item {
  id: root

  property string mood: "chill"
  property bool popped: false
  property real faceSize: 64

  width: faceSize
  height: faceSize * 1.02

  readonly property bool napping: mood === "napping"
  readonly property bool soaked: mood === "soaked"
  readonly property bool munching: mood === "munching"
  readonly property bool hyped: mood === "hyped"
  readonly property bool fried: mood === "fried"
  readonly property bool lonely: mood === "lonely"
  readonly property bool meh: mood === "meh"

  Image {
    id: portrait
    anchors.fill: parent
    source: Qt.resolvedUrl("capy.png")
    fillMode: Image.PreserveAspectFit
    smooth: true
    opacity: root.napping ? 0.78 : (root.meh ? 0.88 : 1)
    scale: root.popped ? 1.08 : 1
    transformOrigin: Item.Center
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
    Behavior on opacity { NumberAnimation { duration: 180 } }
  }

  Rectangle {
    visible: root.fried
    anchors.fill: portrait
    radius: 6
    color: "#88C45A28"
  }

  // water drops
  Repeater {
    model: root.soaked ? 3 : 0
    delegate: Rectangle {
      required property int index
      width: root.faceSize * 0.10
      height: width * 1.35
      radius: width
      color: "#7EC8E3"
      opacity: 0.92
      x: root.width * (0.18 + index * 0.28)
      y: root.height * (index === 1 ? 0.00 : 0.06)
    }
  }

  // orange
  Rectangle {
    visible: root.munching
    width: root.faceSize * 0.22
    height: width
    radius: width / 2
    color: "#F08A24"
    border.color: "#C46A12"
    border.width: 1
    x: root.width * 0.72
    y: root.height * 0.52
    Rectangle {
      anchors.centerIn: parent
      width: parent.width * 0.32
      height: width
      radius: width / 2
      color: "#F6D27A"
    }
  }

  Text {
    visible: root.napping
    text: "z"
    color: "#E8D5B0"
    opacity: 0.8
    font.pixelSize: Math.max(9, root.faceSize * 0.22)
    font.bold: true
    x: root.width * 0.78
    y: 0
  }

  Text {
    visible: root.hyped
    text: "*"
    color: "#F6D27A"
    font.pixelSize: Math.max(11, root.faceSize * 0.28)
    x: root.width * 0.78
    y: -root.faceSize * 0.04
  }

  Text {
    visible: root.fried
    text: "~"
    color: "#E8D5B0"
    font.pixelSize: Math.max(10, root.faceSize * 0.24)
    x: root.width * 0.08
    y: 0
  }

  Text {
    visible: root.lonely
    text: "..."
    color: "#E8D5B0"
    opacity: 0.7
    font.pixelSize: Math.max(8, root.faceSize * 0.16)
    x: root.width * 0.72
    y: root.height * 0.08
  }
}
