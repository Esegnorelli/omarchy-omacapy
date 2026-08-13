import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
  readonly property string langHintPath: stateDir + "/omacapy-lang"
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
  readonly property string scanPath: configHome + "/omarchy/plugins/esegnorelli.omacapy/scan-focus.sh"
  readonly property string githubPath: configHome + "/omarchy/plugins/esegnorelli.omacapy/github-scan.sh"

  property var store: Model.defaultState(Date.now())
  property bool hydrateDone: false
  property string nvimHint: ""
  property string focusProcs: ""
  property string focusLangId: ""
  property var stack: []
  property var github: Model.emptyGithub()

  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string winTitle: toplevel ? (toplevel.title || "") : ""
  readonly property string winApp: toplevel ? (toplevel.appId || "") : ""
  readonly property var liveLang: Model.langById(focusLangId)
  readonly property var shownLang: Model.badgeLang(store, focusLangId)
  readonly property var shownStat: Model.languageStat(store, shownLang ? shownLang.id : "")
  readonly property real shownScore: Model.practiceScore(shownStat.ms)
  readonly property bool live: !!liveLang
  readonly property var githubInbox: Model.githubRows(github)
  readonly property int githubCount: Model.githubBadgeCount(github)

  function persist() {
    if (!hydrateDone) return
    stateFile.setText(Model.serializeState(store))
  }

  function applyHint(raw) {
    var line = String(raw || "").trim()
    var nl = line.indexOf("\n")
    if (nl !== -1) line = line.slice(0, nl)
    line = line.trim()
    if (line !== nvimHint) nvimHint = line
  }

  function resolveFocus() {
    var lang = Model.detectLanguage(winTitle, winApp, nvimHint, focusProcs)
    var id = lang ? lang.id : ""
    if (id !== focusLangId) focusLangId = id
    stack = Model.stackRows(store, focusLangId)
  }

  function runTick() {
    resolveFocus()
    store = Model.tickPractice(store, focusLangId, Date.now())
    stack = Model.stackRows(store, focusLangId)
    if (hydrateDone) persist()
  }

  function refreshGithub() {
    if (!githubProc.running)
      githubProc.running = true
  }

  function applyGithub(raw) {
    github = Model.parseGithub(raw)
  }

  function openUrl(url) {
    if (!url) return
    Quickshell.execDetached(["xdg-open", url])
  }

  onWinTitleChanged: resolveFocus()
  onWinAppChanged: resolveFocus()
  onNvimHintChanged: resolveFocus()

  onOpenedChanged: {
    if (opened) {
      runTick()
      refreshGithub()
    }
  }

  Component.onCompleted: {
    mkdirProc.running = true
    if (!scanProc.running) scanProc.running = true
    if (!hintProc.running) hintProc.running = true
    refreshGithub()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", root.stateDir]
    onExited: Qt.callLater(function() { stateFile.reload() })
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: {
      if (root.hydrateDone) return
      root.store = Model.parseState(text(), Date.now())
      root.hydrateDone = true
      root.runTick()
    }
    onLoadFailed: {
      if (root.hydrateDone) return
      root.store = Model.defaultState(Date.now())
      root.hydrateDone = true
      root.persist()
    }
  }

  FileView {
    id: langHintFile
    path: root.langHintPath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyHint(text())
    onLoadFailed: root.applyHint("")
  }

  Process {
    id: hintProc
    command: ["cat", root.langHintPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyHint(text)
    }
  }

  Process {
    id: scanProc
    command: ["sh", root.scanPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var next = String(text || "").replace(/\n/g, " ").trim()
        if (next !== "") root.focusProcs = next
        root.resolveFocus()
      }
    }
  }

  Process {
    id: githubProc
    command: ["sh", root.githubPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyGithub(text)
    }
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: root.runTick()
  }

  Timer {
    interval: 180000
    running: true
    repeat: true
    onTriggered: root.refreshGithub()
  }

  Timer {
    interval: 1500
    running: true
    repeat: true
    onTriggered: {
      if (!hintProc.running) hintProc.running = true
      if (!scanProc.running) scanProc.running = true
      root.resolveFocus()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.shownLang ? root.shownLang.short : "dev"
    labelVisible: false
    useActiveColor: false
    fixedWidth: root.bar && root.bar.vertical ? -1 : Style.space(root.githubCount > 0 ? 76 : 64)
    fixedHeight: root.bar && root.bar.vertical ? Style.space(36) : -1
    horizontalMargin: 6
    tooltipText: Model.tooltip(root.store, root.focusLangId, root.github)
    opacity: root.live ? 1 : 0.72
    active: root.live || root.githubCount > 0
    onPressed: function(b) {
      if (b === Qt.MiddleButton) {
        root.openUrl("https://github.com/notifications")
        return
      }
      if (b === Qt.LeftButton) root.toggle()
    }

    Column {
      anchors.centerIn: parent
      spacing: 2

      Row {
        spacing: Style.space(5)
        Text {
          text: root.shownLang ? root.shownLang.icon : "{}"
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: Style.font.title
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          visible: !(root.bar && root.bar.vertical)
          text: {
            var label = root.shownLang ? root.shownLang.short : "dev"
            if (root.githubCount > 0) label += " " + root.githubCount
            return label
          }
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Rectangle {
        visible: !!root.shownLang && !(root.bar && root.bar.vertical)
        width: parent.width
        height: 2
        radius: 1
        color: Style.selectedFillFor(button.foreground, Color.accent)
        Rectangle {
          width: parent.width * (root.shownScore / 100)
          height: parent.height
          radius: 1
          color: Color.accent
        }
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
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        Column {
          width: parent.width
          spacing: Style.space(4)

          Text {
            width: parent.width
            text: root.liveLang ? root.liveLang.name : "Stack"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            width: parent.width
            text: root.liveLang
              ? ("In focus · " + Model.formatDuration(root.shownStat.todayMs) + " today · "
                 + Model.formatDuration(root.shownStat.weekMs) + " this week")
              : "Hours in each language and AI tool. GitHub via gh."
            color: root.bar.foreground
            opacity: 0.65
            wrapMode: Text.WordWrap
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            width: parent.width
            text: root.github.ok
              ? ("GitHub · @" + root.github.login)
              : "GitHub"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            opacity: 0.7
          }

          Text {
            width: parent.width
            visible: !root.github.ok
            text: root.github.error || "Uses the GitHub CLI. Run gh auth login."
            color: root.bar.foreground
            opacity: 0.55
            wrapMode: Text.WordWrap
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Text {
            width: parent.width
            visible: root.github.ok
            text: root.github.notificationCount + " inbox · "
                  + root.github.reviewCount + " review · "
                  + root.github.prCount + " your PRs"
            color: root.bar.foreground
            opacity: 0.65
            wrapMode: Text.WordWrap
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: root.githubInbox
            delegate: BorderSurface {
              required property var modelData
              width: parent.width
              implicitHeight: ghCol.implicitHeight + Style.space(12)
              radius: Style.cornerRadius
              color: ghMouse.containsMouse
                ? Style.hoverFillFor(root.bar.foreground, Color.accent)
                : "transparent"
              borderSpec: Border.none()

              Column {
                id: ghCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(8)
                anchors.rightMargin: Style.space(8)
                spacing: 2
                Text {
                  text: modelData.label
                  color: Color.accent
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                }
                Text {
                  width: parent.width
                  text: modelData.title
                  color: root.bar.foreground
                  wrapMode: Text.WordWrap
                  elide: Text.ElideRight
                  maximumLineCount: 2
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }

              MouseArea {
                id: ghMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (modelData.url) root.openUrl(modelData.url)
                  else root.openUrl("https://github.com/notifications")
                }
              }
            }
          }

          Text {
            width: parent.width
            visible: root.github.ok
            text: "Middle-click badge · github.com/notifications"
            color: root.bar.foreground
            opacity: 0.4
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        Text {
          width: parent.width
          visible: root.stack.length === 0
          text: "Open a .py / .rs / .go file, or focus OpenCode / Claude / Grok. In nvim, copy nvim/omacapy.lua into ~/.config/nvim/plugin/."
          color: root.bar.foreground
          opacity: 0.55
          wrapMode: Text.WordWrap
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Repeater {
          model: root.stack
          delegate: Column {
            required property var modelData
            width: parent.width
            spacing: Style.space(4)

            Row {
              width: parent.width
              spacing: Style.space(8)
              Text {
                text: modelData.icon
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                anchors.verticalCenter: parent.verticalCenter
              }
              Column {
                width: parent.width - 28
                spacing: 1
                Row {
                  width: parent.width
                  Text {
                    width: parent.width * 0.45
                    text: modelData.name
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: modelData.active
                    elide: Text.ElideRight
                  }
                  Text {
                    width: parent.width * 0.55
                    horizontalAlignment: Text.AlignRight
                    text: modelData.weekText + " wk · " + modelData.totalText
                    color: root.bar.foreground
                    opacity: 0.7
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                }
                Rectangle {
                  width: parent.width
                  height: Style.space(6)
                  radius: height / 2
                  color: Style.selectedFillFor(root.bar.foreground, Color.accent)
                  Rectangle {
                    width: parent.width * (modelData.score / 100)
                    height: parent.height
                    radius: parent.radius
                    color: modelData.active ? Color.accent : Qt.darker(Color.accent, 1.25)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
