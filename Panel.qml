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
  property int cursorIndex: 0
  property bool cursorActive: false
  property bool actionPop: false
  property real heroScale: 1
  property real toastOpacity: 0
  property string toastText: ""
  property var particles: []
  property int particleSeq: 0
  property real loungeOpacity: 0
  property real loungeSlide: 8

  readonly property var meta: Model.moodMeta(capy.mood)
  readonly property var meters: Model.meters(capy)
  readonly property var actions: Model.actions()
  readonly property string rank: Model.bondRank(capy.bond)
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color dim: Qt.darker(fg, 1.45)
  readonly property color moodColor: capy.mood === "fried"
    ? (bar ? bar.urgent : Color.urgent)
    : Color.accent

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

  function burstColor(actionId) {
    if (actionId === "pet") return "#E8C9A0"
    if (actionId === "orange") return "#F08A24"
    if (actionId === "soak") return "#7EC8E3"
    return ""
  }

  function spawnParticles(actionId) {
    var tint = burstColor(actionId)
    var next = []
    for (var i = 0; i < 5; i++) {
      particleSeq += 1
      next.push({
        id: particleSeq,
        x: 28 + i * 22 + ((particleSeq + i) % 3) * 6,
        delay: i * 45,
        tint: tint,
      })
    }
    particles = next
    particleClear.restart()
  }

  function playActionMotion(actionId) {
    actionPop = true
    heroScale = actionId === "soak" ? 1.08 : 1.10
    popBack.restart()
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
      loungeOpacity = 0
      loungeSlide = 8
      openAnim.restart()
    } else {
      loungeOpacity = 0
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
    id: popBack
    interval: 220
    running: false
    repeat: false
    onTriggered: {
      root.heroScale = 1
      root.actionPop = false
    }
  }

  Timer {
    id: toastFade
    interval: 1800
    running: false
    repeat: false
    onTriggered: root.toastOpacity = 0
  }

  Timer {
    id: particleClear
    interval: 780
    running: false
    repeat: false
    onTriggered: root.particles = []
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "loungeOpacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
      NumberAnimation { target: root; property: "loungeSlide"; to: 0; duration: 240; easing.type: Easing.OutCubic }
    }
  }

  Behavior on heroScale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  Behavior on toastOpacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

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
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
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
        opacity: root.loungeOpacity
        y: root.loungeSlide

        Item {
          width: parent.width
          height: Math.max(heroFace.height, heroCopy.height)

          Repeater {
            model: root.particles
            delegate: Rectangle {
              required property var modelData
              width: 5
              height: 5
              radius: 2.5
              color: modelData.tint !== "" ? modelData.tint : Color.accent
              opacity: 0
              x: modelData.x
              y: 36

              SequentialAnimation on opacity {
                running: true
                PauseAnimation { duration: modelData.delay }
                NumberAnimation { from: 0; to: 0.9; duration: 80 }
                NumberAnimation { from: 0.9; to: 0; duration: 520; easing.type: Easing.InQuad }
              }
              SequentialAnimation on y {
                running: true
                PauseAnimation { duration: modelData.delay }
                NumberAnimation { from: 40; to: 4; duration: 620; easing.type: Easing.OutCubic }
              }
            }
          }

          CapyFace {
            id: heroFace
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            faceSize: Style.space(72)
            mood: root.capy.mood
            popped: root.actionPop
            scale: root.heroScale
            transformOrigin: Item.Center
          }

          Column {
            id: heroCopy
            anchors.left: heroFace.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Text {
              width: parent.width
              text: "OmaCapy"
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              width: parent.width
              text: root.meta.title.toUpperCase()
              color: root.moodColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
            }

            Text {
              width: parent.width
              text: root.rank + "  ·  CPU " + root.loadAvg.toFixed(2)
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(18)

          Repeater {
            model: root.meters
            delegate: Column {
              required property var modelData
              width: (parent.width - Style.space(36)) / 3
              spacing: Style.space(5)

              Text {
                text: modelData.label.toUpperCase()
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.letterSpacing: 1
              }

              Text {
                text: Math.round(modelData.value) + "%"
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Rectangle {
                width: parent.width
                height: Style.space(4)
                radius: height / 2
                color: Style.selectedFillFor(root.fg, Color.accent)

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
        }

        PanelSeparator { foreground: root.fg }

        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "ACTIONS"
            foreground: root.fg
            fontFamily: root.fontFamily
          }

          Repeater {
            model: root.actions
            delegate: Button {
              required property var modelData
              required property int index
              width: parent.width
              text: modelData.label
              tooltipText: modelData.detail
              leftAlign: true
              foreground: root.fg
              fontFamily: root.fontFamily
              hasCursor: root.cursorActive && root.cursorIndex === index
              onHovered: function(on) {
                if (on) {
                  root.cursorActive = true
                  root.cursorIndex = index
                }
              }
              onClicked: root.doAction(modelData.id)

              Text {
                anchors.right: parent.right
                anchors.rightMargin: Style.space(12)
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.detail
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.toastText !== "" || root.capy.lastWisdom !== ""

          PanelSeparator { foreground: root.fg }

          Text {
            width: parent.width
            visible: root.toastText !== ""
            opacity: root.toastOpacity
            text: root.toastText
            color: Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.8
          }

          Text {
            width: parent.width
            visible: root.capy.lastWisdom !== ""
            text: root.capy.lastWisdom
            color: root.fg
            opacity: 0.82
            wrapMode: Text.WordWrap
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }
    }
  }
}
