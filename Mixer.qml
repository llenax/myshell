import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

//  Mixer — pavucontrol-style window
//  Set mixerVisible = true to open

Item {
  id: root

  // ── public API ──────────────────────────────────────────────
  property bool mixerVisible: false

  onMixerVisibleChanged: {
    if (mixerVisible) {
      win.visible = true
      refresh()
    } else {
      win.visible = false
    }
  }

  // ── state ───────────────────────────────────────────────────
  property var sinkInputs:    []
  property var sinks:         []
  property var sourceOutputs: []
  property var sources:       []
  property bool anyDragging:  false

  property string lastPactlEvent: ""

  function refresh() {
    getSinkInputs.running    = true
    getSinks.running         = true
    getSourceOutputs.running = true
    getSources.running       = true
  }

  // ════════════════════════════════════════════════════════════
  //  Data
  // ════════════════════════════════════════════════════════════
  Process {
    id: getSinkInputs
    command: ["pactl", "list", "sink-inputs"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: root.sinkInputs = parsePactlBlocks(this.text, "Sink Input #")
    }
  }

  Process {
    id: getSinks
    command: ["pactl", "list", "sinks"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: root.sinks = parseSinkSource(this.text, "Sink #")
    }
  }

  Process {
    id: getSourceOutputs
    command: ["pactl", "list", "source-outputs"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: root.sourceOutputs = parsePactlBlocks(this.text, "Source Output #")
    }
  }

  Process {
    id: getSources
    command: ["pactl", "list", "sources"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: root.sources = parseSinkSource(this.text, "Source #")
        .filter(s => !s.name.includes(".monitor"))
    }
  }

  // Process {
  //   id: watchPactl
  //   command: ["pactl", "subscribe"]
  //   running: false
  //   stdout: SplitParser {
  //     onRead: msg => { if (!root.anyDragging) refresh() }
  //   }
  // }
  
  FileView {
    id: pactl_event
    path: Qt.resolvedUrl("/tmp/pactl_event")
    blockLoading: true
  }

  Timer {
    interval: 200
    repeat: true
    running: true
    onTriggered: {
      var text = pactl_event.text()
      if (text !== lastPactlEvent) {
        lastPactlEvent = text
        refresh()
      }
    }
  }

  Timer {
    interval: 3000
    running:  !root.anyDragging
    repeat:   true
    onTriggered: refresh()
  }

  // ════════════════════════════════════════════════════════════
  //  Helpers
  // ════════════════════════════════════════════════════════════
  function parsePactlBlocks(text, prefix) {
    const binaryIconMap = { "helium": "helium-browser" }
    return text.split(prefix).slice(1).map(block => {
      const nameMatch   = block.match(/application\.name = "([^"]+)"/)
      const iconMatch   = block.match(/application\.icon-name = "([^"]+)"/)
      const binaryMatch = block.match(/application\.process\.binary = "([^"]+)"/)
      const volMatch    = block.match(/Volume:.*?(\d+)%/)
      const muteMatch   = block.match(/Mute: (yes|no)/)
      const idMatch     = block.match(/^(\d+)/)
      const binary = binaryMatch ? binaryMatch[1].toLowerCase() : null
      return {
        id:          idMatch   ? idMatch[1]   : null,
        name:        nameMatch ? nameMatch[1] : "Unknown",
        icon:        iconMatch ? iconMatch[1]
                     : binary && binaryIconMap[binary] ? binaryIconMap[binary]
                     : binary ?? "audio-x-generic",
        vol:         volMatch  ? parseInt(volMatch[1]) : 100,
        muted:       muteMatch ? muteMatch[1] === "yes" : false,
        deviceState: "",
        desc:        "",
      }
    }).filter(a => a.id !== null)
  }

  function parseSinkSource(text, prefix) {
    return text.split(prefix).slice(1).map(block => {
      const idMatch    = block.match(/^(\d+)/)
      const nameMatch  = block.match(/Name: ([^\n]+)/)
      const descMatch  = block.match(/Description: ([^\n]+)/)
      const volMatch   = block.match(/Volume:.*?(\d+)%/)
      const muteMatch  = block.match(/Mute: (yes|no)/)
      const stateMatch = block.match(/State: ([^\n]+)/)
      return {
        id:          idMatch    ? idMatch[1].trim()    : null,
        name:        nameMatch  ? nameMatch[1].trim()  : "Unknown",
        desc:        descMatch  ? descMatch[1].trim()  : "Unknown Device",
        vol:         volMatch   ? parseInt(volMatch[1]) : 100,
        muted:       muteMatch  ? muteMatch[1] === "yes" : false,
        deviceState: stateMatch ? stateMatch[1].trim() : "",
        icon:        "audio-x-generic",
      }
    }).filter(a => a.id !== null)
  }

  // ════════════════════════════════════════════════════════════
  //  Window
  // ════════════════════════════════════════════════════════════
  FloatingWindow {
    id: win
    visible: false
    width:   560
    height:  480
    title:   "Mixer"
    color:   "transparent"

    onVisibleChanged: {
      if (!visible && root.mixerVisible) root.mixerVisible = false
    }

    HyprlandFocusGrab {
      windows: [win]
      active:  win.visible
      onCleared: root.mixerVisible = false
    }

    Rectangle {
      anchors.fill: parent
      color:  Theme.bg
      radius: 0

      Rectangle {
        width: parent.width; height: 2
        color: Theme.purple
      }

      ColumnLayout {
        id: winContent
        anchors.fill:    parent
        anchors.margins: 0
        spacing: 0

        property int activeTab: 0

        // ── title bar ────────────────────────────────────────
        Rectangle {
          Layout.fillWidth: true
          height: 40
          color:  "transparent"

          RowLayout {
            anchors.fill:        parent
            anchors.leftMargin:  16
            anchors.rightMargin: 10
            anchors.topMargin:   2

            Text {
              text: "  Mixer"
              font.family:    "Hack Nerd Font"
              font.pixelSize: 14
              color: Theme.fg
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              width: 24; height: 24; radius: 12
              color: closeHover ? Theme.slateD : "transparent"
              Behavior on color { ColorAnimation { duration: 100 } }
              property bool closeHover: false

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 11
                color: Theme.fgMuted
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:    parent.closeHover = true
                onExited:     parent.closeHover = false
                onClicked:    root.mixerVisible = false
              }
            }
          }
        }

        // ── tab bar ───────────────────────────────────────────
        RowLayout {
          Layout.fillWidth:  true
          Layout.leftMargin: 12
          spacing: 2

          Repeater {
            model: ["  Playback", "  Output", "  Input", "  Recording"]

            Rectangle {
              required property string modelData
              required property int    index

              height: 30
              width:  tabLabel.implicitWidth + 24
              radius: 4
              color:  winContent.activeTab === index ? Theme.slateD : "transparent"
              Behavior on color { ColorAnimation { duration: 100 } }

              Rectangle {
                visible: winContent.activeTab === index
                width:   parent.width - 16; height: 2
                anchors.bottom:           parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                color:  index < 2 ? Theme.purple : Theme.blue
                radius: 1
              }

              Text {
                id: tabLabel
                anchors.centerIn: parent
                text: modelData
                font.family:    "Hack Nerd Font"
                font.pixelSize: 12
                color: winContent.activeTab === index ? Theme.fg : Theme.fgMuted
              }

              MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    winContent.activeTab = index
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color:  Theme.slateD
        }

        // ── tab content ───────────────────────────────────────
        Item {
          Layout.fillWidth:  true
          Layout.fillHeight: true
          clip: true

          MixerTab {
            anchors.fill: parent
            visible:      winContent.activeTab === 0
            entries:      root.sinkInputs
            accentColor:  Theme.purple
            emptyText:    "No playback streams"
            emptyIcon:    "󰝛"
            onVolumeChanged: (id, vol) => Quickshell.execDetached(["pactl", "set-sink-input-volume",    id, vol + "%"])
            onMuteToggled:   (id)      => Quickshell.execDetached(["pactl", "set-sink-input-mute",     id, "toggle"])
            onDraggingChanged: (v)     => root.anyDragging = v
          }

          MixerTab {
            anchors.fill: parent
            visible:      winContent.activeTab === 1
            entries:      root.sinks
            accentColor:  Theme.purple
            isDevice:     true
            emptyText:    "No output devices"
            emptyIcon:    "󰓃"
            onVolumeChanged: (id, vol) => Quickshell.execDetached(["pactl", "set-sink-volume",         id, vol + "%"])
            onMuteToggled:   (id)      => Quickshell.execDetached(["pactl", "set-sink-mute",           id, "toggle"])
            onDraggingChanged: (v)     => root.anyDragging = v
          }

          MixerTab {
            anchors.fill: parent
            visible:      winContent.activeTab === 2
            entries:      root.sources
            accentColor:  Theme.blue
            isDevice:     true
            emptyText:    "No input devices"
            emptyIcon:    "󰍭"
            onVolumeChanged: (id, vol) => Quickshell.execDetached(["pactl", "set-source-volume",       id, vol + "%"])
            onMuteToggled:   (id)      => Quickshell.execDetached(["pactl", "set-source-mute",         id, "toggle"])
            onDraggingChanged: (v)     => root.anyDragging = v
          }

          MixerTab {
            anchors.fill: parent
            visible:      winContent.activeTab === 3
            entries:      root.sourceOutputs
            accentColor:  Theme.blue
            emptyText:    "No recording streams"
            emptyIcon:    "󰍮"
            onVolumeChanged: (id, vol) => Quickshell.execDetached(["pactl", "set-source-output-volume", id, vol + "%"])
            onMuteToggled:   (id)      => Quickshell.execDetached(["pactl", "set-source-output-mute",   id, "toggle"])
            onDraggingChanged: (v)     => root.anyDragging = v
          }
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  //  MixerTab component
  // ════════════════════════════════════════════════════════════
  component MixerTab: Item {
    id: tab

    property var    entries:     []
    property color  accentColor: Theme.purple
    property bool   isDevice:    false
    property string emptyText:   "Nothing here"
    property string emptyIcon:   "󰝛"

    signal volumeChanged(string id, int vol)
    signal muteToggled(string id)
    signal draggingChanged(bool dragging)

    Column {
      anchors.centerIn: parent
      spacing: 10
      visible: tab.entries.length === 0

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: tab.emptyIcon
        font.family:    "Hack Nerd Font"
        font.pixelSize: 36
        color: Theme.slateD
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: tab.emptyText
        font.family:    Theme.font
        font.pixelSize: 13
        color: Theme.fgMuted
      }
    }

    Flickable {
      id: tabFlick
      anchors.fill:    parent
      anchors.margins: 12
      clip:            true
      contentWidth:    width
      contentHeight:   col.implicitHeight
      boundsBehavior:  Flickable.StopAtBounds
      interactive:     false
      visible:         tab.entries.length > 0

      ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        visible: tabFlick.contentHeight > tabFlick.height
      }

      WheelHandler {
        target: tabFlick
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (e) => {
          const step = 40
          tabFlick.contentY = e.angleDelta.y > 0
            ? Math.max(0, tabFlick.contentY - step)
            : Math.min(Math.max(0, tabFlick.contentHeight - tabFlick.height), tabFlick.contentY + step)
          e.accepted = true
        }
      }

      ColumnLayout {
        id: col
        width:   tabFlick.width - 8
        spacing: 6

        Repeater {
          model: tab.entries

          Rectangle {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            height:           cardCol.implicitHeight + 20
            radius:           6
            color:            Theme.slateD
            opacity:          modelData.muted ? 0.6 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            property int localVol: modelData.vol
            onModelDataChanged: {
              if (!debounce.running) localVol = modelData.vol
            }

            Timer {
              id: debounce
              interval: 300
              repeat:   false
              onTriggered: tab.volumeChanged(modelData.id, appSlider.value)
            }

            ColumnLayout {
              id: cardCol
              anchors.left:    parent.left
              anchors.right:   parent.right
              anchors.top:     parent.top
              anchors.margins: 10
              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                  width: 16; height: 16
                  visible: !tab.isDevice

                  Image {
                    id: cardImg
                    anchors.fill:      parent
                    source:            Quickshell.iconPath(modelData.icon, "audio-x-generic")
                    fillMode:          Image.PreserveAspectFit
                    sourceSize.width:  16
                    sourceSize.height: 16
                    smooth:            true
                    visible:           status === Image.Ready
                  }
                  Text {
                    visible:        cardImg.status !== Image.Ready
                    anchors.fill:   parent
                    text:           " "
                    font.family:    "Hack Nerd Font"
                    font.pixelSize: 13
                    color:          Theme.fgMuted
                  }
                }

                Text {
                  visible:        tab.isDevice
                  text:           tab.accentColor === Theme.purple ? "󰓃" : "󰍭"
                  font.family:    "Hack Nerd Font"
                  font.pixelSize: 14
                  color:          tab.accentColor
                }

                Text {
                  text:             tab.isDevice ? modelData.desc : modelData.name
                  font.family:      Theme.font
                  font.pixelSize:   13
                  color:            Theme.fg
                  elide:            Text.ElideRight
                  Layout.fillWidth: true
                }

                Rectangle {
                  visible: tab.isDevice && modelData.deviceState !== ""
                  width:   stateLbl.implicitWidth + 10
                  height:  16; radius: 8
                  color:   modelData.deviceState === "RUNNING"
                           ? Qt.rgba(tab.accentColor.r, tab.accentColor.g, tab.accentColor.b, 0.2)
                           : Qt.rgba(0.3, 0.3, 0.3, 0.3)

                  Text {
                    id: stateLbl
                    anchors.centerIn: parent
                    text:           modelData.deviceState
                    font.family:    Theme.font
                    font.pixelSize: 9
                    color: modelData.deviceState === "RUNNING" ? tab.accentColor : Theme.fgMuted
                  }
                }

                Text {
                  text:                localVol + "%"
                  font.family:         Theme.font
                  font.pixelSize:      12
                  color:               Theme.fgMuted
                  Layout.minimumWidth: 34
                  horizontalAlignment: Text.AlignRight
                }

                Rectangle {
                  width: 36; height: 18; radius: 9
                  color: modelData.muted
                         ? Theme.slateD
                         : Qt.rgba(tab.accentColor.r, tab.accentColor.g, tab.accentColor.b, 0.25)
                  Behavior on color { ColorAnimation { duration: 150 } }

                  Rectangle {
                    width: 14; height: 14; radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    x:     modelData.muted ? 2 : parent.width - 16
                    color: modelData.muted ? Theme.fgMuted : tab.accentColor
                    Behavior on x { NumberAnimation { duration: 150 } }
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    tab.muteToggled(modelData.id)
                  }
                }
              }

              Slider {
                id: appSlider
                Layout.fillWidth: true
                from: 0; to: 150
                value: localVol
                stepSize: 1

                onPressedChanged: tab.draggingChanged(pressed)
                onMoved: {
                  localVol = value
                  debounce.restart()
                }

                background: Rectangle {
                  x:      appSlider.leftPadding
                  y:      appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                  width:  appSlider.availableWidth
                  height: 4; radius: 2
                  color:  Theme.bg

                  Rectangle {
                    width:  Math.min(appSlider.visualPosition, 100/150) * parent.width
                    height: parent.height; radius: 2
                    color:  tab.accentColor
                  }

                  Rectangle {
                    x:      (100/150) * parent.width
                    width:  Math.max(0, appSlider.visualPosition - 100/150) * parent.width
                    height: parent.height; radius: 2
                    color:  Qt.rgba(tab.accentColor.r, tab.accentColor.g, tab.accentColor.b, 0.45)
                  }

                  Rectangle {
                    x:      (100/150) * parent.width - 1
                    width:  2; height: parent.height + 4
                    anchors.verticalCenter: parent.verticalCenter
                    color:  Qt.rgba(1, 1, 1, 0.15)
                    radius: 1
                  }
                }
              }

            } // cardCol
          } // card

        } // Repeater

        Item { height: 4 }
      } // col
    } // Flickable
  } // component MixerTab

}
