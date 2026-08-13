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
  property bool hydrateDone: false
  property int frame: 0
  property int cursorIndex: 0
  property bool cursorActive: false
  property bool actionPop: false
  property real heroScale: 1
  property real heroSpin: 0
  property real barNudge: 0
  property real toastOpacity: 0
  property string toastText: ""
  property var particles: []
  property int particleSeq: 0

  readonly property var meta: Model.moodMeta(capy.mood)
  readonly property var meters: Model.meters(capy)
  readonly property int animTempo: Model.barTempoMs(capy)
  readonly property var actions: Model.actions()

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

  function showToast(text) {
    toastText = text || ""
    toastOpacity = toastText !== "" ? 1 : 0
    if (toastText !== "")
      toastFade.restart()
  }

  function spawnParticles(actionId) {
    var fx = Model.actionFx(actionId)
    var next = []
    for (var i = 0; i < fx.length; i++) {
      particleSeq += 1
      next.push({
        id: particleSeq,
        text: fx[i],
        x: 40 + (i * 70) + ((particleSeq + i) % 3) * 12,
        delay: i * 70,
      })
    }
    particles = next
    particleClear.restart()
  }

  function playActionMotion(actionId) {
    actionPop = true
    heroScale = actionId === "soak" ? 1.18 : 1.28
    heroSpin = actionId === "wisdom" ? 12 : (actionId === "orange" ? -8 : 0)
    barNudge = actionId === "pet" ? -4 : 3
    popBack.restart()
    nudgeBack.restart()
    spawnParticles(actionId)
  }

  function doAction(id) {
    var ts = Date.now()
    if (id === "pet") capy = Model.pet(capy, loadAvg, ts)
    else if (id === "orange") capy = Model.orange(capy, loadAvg, ts)
    else if (id === "soak") capy = Model.soak(capy, loadAvg, ts)
    else if (id === "wisdom") capy = Model.wisdom(capy, loadAvg, ts)
    else return
    persist()
    showToast(capy.toast || "")
    playActionMotion(id)
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
      heroScale = 1
      heroSpin = 0
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

  // world tick
  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: {
      root.refreshLoad()
      root.runTick()
    }
  }

  // sprite frame cycle — tempo depends on mood
  Timer {
    interval: Math.max(180, root.animTempo)
    running: true
    repeat: true
    onTriggered: root.frame = (root.frame + 1) % 8
  }

  // idle bob on the bar badge
  Timer {
    interval: 40
    running: true
    repeat: true
    onTriggered: {
      // gentle sine via frame clock when no action nudge is active
      if (nudgeBack.running) return
      var t = Date.now() / (root.capy.mood === "napping" ? 900 : 420)
      var amp = root.capy.mood === "hyped" ? 2.4 : (root.capy.mood === "fried" ? 1.8 : 1.2)
      root.barNudge = Math.sin(t) * amp
    }
  }

  Timer {
    id: popBack
    interval: 220
    running: false
    repeat: false
    onTriggered: {
      root.heroScale = 1
      root.heroSpin = 0
      root.actionPop = false
    }
  }

  Timer {
    id: nudgeBack
    interval: 180
    running: false
    repeat: false
    onTriggered: root.barNudge = 0
  }

  Timer {
    id: toastFade
    interval: 2200
    running: false
    repeat: false
    onTriggered: root.toastOpacity = 0
  }

  Timer {
    id: particleClear
    interval: 900
    running: false
    repeat: false
    onTriggered: root.particles = []
  }

  Behavior on heroScale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
  Behavior on heroSpin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  Behavior on barNudge { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
  Behavior on toastOpacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.meta.bar
    labelVisible: false
    active: root.capy.mood === "lonely" || root.capy.mood === "fried" || root.capy.mood === "hyped" || root.actionPop
    useActiveColor: root.capy.mood === "lonely" || root.capy.mood === "fried" || root.actionPop
    fixedWidth: root.bar && root.bar.vertical ? -1 : Style.space(58)
    fixedHeight: root.bar && root.bar.vertical ? Style.space(36) : -1
    horizontalMargin: 6
    tooltipText: Model.tooltip(root.capy, root.loadAvg)
    opacity: 0.88 + Math.min(0.12, Math.abs(root.barNudge) * 0.03)
    Behavior on opacity { NumberAnimation { duration: 80 } }
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

    Row {
      anchors.centerIn: parent
      spacing: Style.space(5)
      CapyFace {
        faceSize: Style.space(16)
        mood: root.capy.mood
        popped: root.actionPop
        anchors.verticalCenter: parent.verticalCenter
        y: root.barNudge * 0.4
      }
      Text {
        visible: !(root.bar && root.bar.vertical)
        text: root.meta.bar
        color: button.active && button.useActiveColor ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }
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

        // Hero stage
        Item {
          width: parent.width
          height: heroBlock.implicitHeight + Style.space(18)

          // floating reaction particles
          Repeater {
            model: root.particles
            delegate: Text {
              required property var modelData
              text: modelData.text
              font.pixelSize: Style.font.title
              opacity: 0
              x: modelData.x
              y: 70

              SequentialAnimation on opacity {
                running: true
                PauseAnimation { duration: modelData.delay }
                NumberAnimation { from: 0; to: 1; duration: 90 }
                NumberAnimation { from: 1; to: 0; duration: 650; easing.type: Easing.InQuad }
              }
              SequentialAnimation on y {
                running: true
                PauseAnimation { duration: modelData.delay }
                NumberAnimation { from: 70; to: 4; duration: 780; easing.type: Easing.OutCubic }
              }
            }
          }

          Column {
            id: heroBlock
            width: parent.width
            spacing: Style.space(6)

            CapyFace {
              id: heroFace
              anchors.horizontalCenter: parent.horizontalCenter
              faceSize: Style.space(96)
              mood: root.capy.mood
              popped: root.actionPop
              scale: root.heroScale
              rotation: root.heroSpin
              transformOrigin: Item.Center
              opacity: root.capy.mood === "napping" ? 0.82 : 1

              SequentialAnimation on opacity {
                running: root.opened && root.capy.mood === "napping"
                loops: Animation.Infinite
                NumberAnimation { from: 0.55; to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.0; to: 0.55; duration: 1400; easing.type: Easing.InOutSine }
              }
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
                  Behavior on width {
                    NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                  }
                }
              }
            }
          }

          Text {
            width: parent.width
            text: Model.meterHint()
            color: root.bar.foreground
            opacity: 0.48
            wrapMode: Text.WordWrap
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
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
              scale: actionMouse.pressed ? 0.98 : 1
              Behavior on scale { NumberAnimation { duration: 90 } }
              Behavior on color { ColorAnimation { duration: 120 } }

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
                  scale: actionMouse.containsMouse ? 1.12 : 1
                  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
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

        // Lore card
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
              visible: root.toastText !== ""
              opacity: root.toastOpacity
              text: root.toastText
              color: Color.accent
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              wrapMode: Text.WordWrap
            }

            Text {
              width: parent.width
              text: root.capy.lastWisdom !== "" ? root.capy.lastWisdom : Model.emptyWisdom()
              color: root.bar.foreground
              opacity: 0.86
              wrapMode: Text.WordWrap
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              width: parent.width
              text: Model.shortcutHint()
              color: root.bar.foreground
              opacity: 0.5
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
                    + " · CPU " + root.loadAvg.toFixed(2)
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
