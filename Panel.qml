import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "esegnorelli.omacapy"
  ipcTarget: "esegnorelli.omacapy"

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
  readonly property string stateDir: stateHome + "/omarchy"
  readonly property string statePath: stateDir + "/omacapy.json"

  property var capy: Model.defaultState(Date.now())
  property real loadAvg: 0
  property bool stateReady: false
  property bool hydrateDone: false
  property int blink: 0
  property int cursorIndex: 0
  property bool cursorActive: false

  readonly property var meta: Model.moodMeta(capy.mood)
  readonly property var meters: Model.meters(capy)
  readonly property var actions: [
    { id: "pet", label: "Pet", detail: "soft diplomacy", icon: "✋" },
    { id: "orange", label: "Orange", detail: "citrus treaty", icon: "🍊" },
    { id: "soak", label: "Soak", detail: "river mode", icon: "💧" },
    { id: "wisdom", label: "Wisdom", detail: "calm nonsense", icon: "💬" },
  ]

  function persist() {
    if (!hydrateDone) return
    stateFile.setText(Model.serializeState(capy))
  }

  function applyLoad(raw) {
    loadAvg = Model.parseLoad(raw)
  }

  function refreshLoad() {
    if (!loadProc.running)
      loadProc.running = true
  }

  function runTick() {
    capy = Model.tick(capy, loadAvg, Date.now())
    if (hydrateDone) persist()
  }

  function doAction(id) {
    var ts = Date.now()
    if (id === "pet") capy = Model.pet(capy, loadAvg, ts)
    else if (id === "orange") capy = Model.orange(capy, loadAvg, ts)
    else if (id === "soak") capy = Model.soak(capy, loadAvg, ts)
    else if (id === "wisdom") capy = Model.wisdom(capy, loadAvg, ts)
    else return
    persist()
    blink = 1
    blinkTimer.restart()
  }

  function selectByDelta(delta) {
    if (!actions.length) return
    cursorIndex = Math.max(0, Math.min(actions.length - 1, cursorIndex + delta))
  }

  function activateSelected() {
    if (cursorIndex < 0 || cursorIndex >= actions.length) return
    doAction(actions[cursorIndex].id)
  }

  onOpenedChanged: {
    if (opened) {
      refreshLoad()
      runTick()
      cursorActive = false
      cursorIndex = 0
    }
  }

  Component.onCompleted: {
    mkdirProc.running = true
    refreshLoad()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", root.stateDir]
    onExited: Qt.callLater(function() { stateFile.reload() })
  }

  Process {
    id: loadProc
    command: ["cat", "/proc/loadavg"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyLoad(text)
    }
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: {
      if (root.hydrateDone) return
      root.capy = Model.parseState(text(), Date.now())
      root.hydrateDone = true
      root.runTick()
    }
    onLoadFailed: {
      if (root.hydrateDone) return
      root.capy = Model.defaultState(Date.now())
      root.hydrateDone = true
      root.persist()
    }
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: {
      root.refreshLoad()
      root.runTick()
    }
  }

  Timer {
    id: blinkTimer
    interval: 650
    running: false
    repeat: false
    onTriggered: root.blink = 0
  }

  // gentle face pulse while lounge open
  Timer {
    interval: 900
    running: root.opened
    repeat: true
    onTriggered: root.blink = root.blink === 1 ? 0 : 1
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.meta.bar
    active: root.capy.mood === "lonely" || root.capy.mood === "fried" || root.capy.mood === "hyped"
    useActiveColor: root.capy.mood === "lonely" || root.capy.mood === "fried"
    fixedWidth: root.bar && root.bar.vertical ? -1 : Style.space(34)
    fixedHeight: root.bar && root.bar.vertical ? Style.space(28) : -1
    horizontalMargin: 6
    tooltipText: Model.tooltip(root.capy, root.loadAvg)
    onPressed: function(b) {
      if (b === Qt.MiddleButton) {
        root.doAction("pet")
        return
      }
      if (b === Qt.RightButton) {
        root.doAction("wisdom")
        return
      }
      root.toggle()
    }
    onWheelMoved: function(delta) {
      if (delta > 0) root.doAction("pet")
      else root.doAction("orange")
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) {
          root.cursorActive = true
          return
        }
        if (dy !== 0) root.selectByDelta(dy)
        else if (dx !== 0) root.selectByDelta(dx)
      }
      onActivateRequested: if (root.cursorActive) root.activateSelected()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        // Hero
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.blink ? root.meta.face : root.meta.face
            font.pixelSize: Style.font.title * 2.2
            opacity: root.blink ? 0.84 : 1
            Behavior on opacity { NumberAnimation { duration: 180 } }
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "OmaCapy"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.meta.title
            color: root.bar ? root.bar.urgent : Color.urgent
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.meta.blurb
            color: root.bar.foreground
            opacity: 0.75
            wrapMode: Text.WordWrap
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        // Meters
        Column {
          width: parent.width
          spacing: Style.space(8)

          Repeater {
            model: root.meters
            delegate: Column {
              required property var modelData
              width: parent.width
              spacing: Style.space(4)

              Row {
                width: parent.width
                Text {
                  width: parent.width * 0.42
                  text: modelData.label
                  color: root.bar.foreground
                  opacity: 0.7
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
                Text {
                  width: parent.width * 0.58
                  horizontalAlignment: Text.AlignRight
                  text: Math.round(modelData.value) + "%"
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                }
              }

              Rectangle {
                width: parent.width
                height: Style.space(8)
                radius: height / 2
                color: Style.selectedFillFor(root.bar.foreground, Color.accent)

                Rectangle {
                  width: parent.width * (modelData.value / 100)
                  height: parent.height
                  radius: parent.radius
                  color: Color.accent
                  Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
              }
            }
          }
        }

        // Actions
        Column {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.actions
            delegate: BorderSurface {
              required property var modelData
              required property int index
              width: parent.width
              implicitHeight: actionRow.implicitHeight + Style.space(14)
              radius: Style.cornerRadius
              color: {
                if (root.cursorActive && root.cursorIndex === index)
                  return Style.selectedFillFor(root.bar.foreground, Color.accent)
                return actionMouse.containsMouse
                  ? Style.hoverFillFor(root.bar.foreground, Color.accent)
                  : "transparent"
              }
              borderSpec: (root.cursorActive && root.cursorIndex === index)
                ? Border.controlSpec("focus", root.bar.foreground, Color.accent)
                : Border.none()

              Row {
                id: actionRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(12)
                anchors.rightMargin: Style.space(12)
                spacing: Style.space(12)

                Text {
                  text: modelData.icon
                  font.pixelSize: Style.font.title
                  anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                  width: parent.width - 48
                  spacing: Style.space(2)
                  Text {
                    text: modelData.label
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }
                  Text {
                    text: modelData.detail
                    color: root.bar.foreground
                    opacity: 0.65
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                }
              }

              MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  root.cursorActive = true
                  root.cursorIndex = index
                }
                onClicked: root.doAction(modelData.id)
              }
            }
          }
        }

        // Wisdom / toast / stats
        BorderSurface {
          width: parent.width
          implicitHeight: loreCol.implicitHeight + Style.space(18)
          radius: Style.cornerRadius
          color: Style.hoverFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.none()

          Column {
            id: loreCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.space(12)
            anchors.rightMargin: Style.space(12)
            spacing: Style.space(6)

            Text {
              width: parent.width
              visible: root.capy.toast !== ""
              text: root.capy.toast
              color: Color.accent
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              wrapMode: Text.WordWrap
            }

            Text {
              width: parent.width
              text: root.capy.lastWisdom !== ""
                ? root.capy.lastWisdom
                : "Right-click the bar badge for instant wisdom. Middle-click to pet without opening."
              color: root.bar.foreground
              opacity: 0.86
              wrapMode: Text.WordWrap
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              width: parent.width
              text: "bond " + Math.floor(root.capy.bond)
                    + " · pets " + root.capy.pets
                    + " · oranges " + root.capy.oranges
                    + " · soaks " + root.capy.soaks
                    + " · load " + root.loadAvg.toFixed(2)
              color: root.bar.foreground
              opacity: 0.5
              wrapMode: Text.WordWrap
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }
      }
    }
  }
}
