import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Hyprland

// ── Volume ────────────────────────────────────────────────────
Item {
  id: root
  implicitWidth:  24
  implicitHeight: 24

  property Item barItem: null

  property int  vol:   0
  property bool muted: false
  property var  appVolumes: []
  property bool anySliderDragging: false

  function refresh() {
    getVolume.running = true
    getAppVolumes.running = true
  }

  // ── Data fetching ─────────────────────────────────────────
  Process {
    id: getVolume
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const text = this.text.trim()
        const parts = text.split(" ")
        const newVol = Math.round(parseFloat(parts[1]) * 100) || 0
        const newMuted = text.includes("[MUTED]")

        if ((newVol !== root.vol || newMuted !== root.muted) && !popup.visible) {
          osd.show(newVol, newMuted)  // only show if something changed
        }

        root.vol = newVol
        root.muted = newMuted
      }
    }
  }

  Process {
    id: getAppVolumes
    command: ["pactl", "list", "sink-inputs"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {

        const binaryIconMap = {
          "helium":  "helium-browser",
        }

        const text = this.text
        const blocks = text.split("Sink Input #")
        .slice(1)
        .map(block => {
          const nameMatch  = block.match(/application\.name = "([^"]+)"/)
          const iconMatch  = block.match(/application\.icon-name = "([^"]+)"/)
          const binaryMatch = block.match(/application\.process\.binary = "([^"]+)"/)
          const volMatch   = block.match(/Volume:.*?(\d+)%/)
          const muteMatch  = block.match(/Mute: (yes|no)/)
          const idMatch    = block.match(/^(\d+)/)

          const binary = binaryMatch ? binaryMatch[1].toLowerCase() : null

          return {
            id:    idMatch   ? idMatch[1]            : null,
            name:  nameMatch ? nameMatch[1]          : "Unknown",
            icon: iconMatch ? iconMatch[1]
            : binary && binaryIconMap[binary] ? binaryIconMap[binary]
            : binary ?? "audio-x-generic",
            vol:   volMatch  ? parseInt(volMatch[1]) : 100,
            muted: muteMatch ? muteMatch[1] === "yes": false,
          }
        })
        .filter(a => a.id !== null)
        root.appVolumes = blocks
      }
    }
  }

  Process {
    id: watchVolume
    command: ["pactl", "subscribe"]
    running: true
    stdout: SplitParser {
      onRead: msg => {
        if (msg.includes("sink") && msg.includes("change")) {
          getVolume.running = true  // re-fetch volume
        }
      }
    }
  }

  Timer {
    interval: 2000; running: !anySliderDragging; repeat: true
    onTriggered: refresh()
  }

  // ── Popup ─────────────────────────────────────────────────
  PopupWindow {
    id: popup
    visible: false
    implicitWidth:  280
    implicitHeight: 324

    color: "transparent"
    anchor.item:    barItem ?? volRow
    anchor.edges:   Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Right

    onWindowConnected: {
      focusGrab.active = true
    }

    onVisibleChanged: {
      if (visible) {
        popupRect.height = 0
        popupRect.opacity = 0
        openAnim.restart()
      } else {
        focusGrab.active = false
      }
    }

    HyprlandFocusGrab {
      id: focusGrab
      windows: [popup]
      onCleared: {
        if (popup.visible && !closeAnim.running) closeAnim.restart()
      }
    }

    ParallelAnimation {
      id: openAnim
      NumberAnimation {
        target: popupRect
        property: "height"
        to: 302
        duration: 220
        easing.type: Easing.OutCubic
      }
      NumberAnimation {
        target: popupRect
        property: "opacity"
        to: 1
        duration: 180
        easing.type: Easing.OutCubic
      }
    }

    ParallelAnimation {
      id: closeAnim
      NumberAnimation {
        target: popupRect
        property: "height"
        to: 0
        duration: 160
        easing.type: Easing.InCubic
      }
      NumberAnimation {
        target: popupRect
        property: "opacity"
        to: 0
        duration: 140
        easing.type: Easing.InCubic
      }
      onFinished: popup.visible = false
    }

    Rectangle {
      id: popupRect
      anchors.top: parent.top
      anchors.topMargin: 2
      anchors.left: parent.left
      anchors.right: parent.right
      color: Theme.bg
      clip: true
      radius: 0
      border.width: 0

      layer.enabled: true

      Rectangle {
        width: parent.width
        height: 2
        color: Theme.purple
      }

      Item {
        anchors.fill: parent
        anchors.margins: 12
        clip: true

        Flickable {
          id: flick
          clip: true
          anchors.fill: parent

          ScrollBar.vertical: ScrollBar {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 6

            orientation: Qt.Vertical

            policy: ScrollBar.AsNeeded
            visible: flick.contentHeight > flick.height
            active: flick.moving || flick.flicking
          }

          boundsBehavior: Flickable.StopAtBounds

          interactive: false

          contentWidth:  popupContent.width
          contentHeight: popupContent.implicitHeight

          WheelHandler {
            target: flick
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

            onWheel: (event) => {
              const step = 10   // pixels per wheel tick (change this)

              if (event.angleDelta.y > 0) {
                flick.contentY = Math.max(0, flick.contentY - step)
              } else {
                flick.contentY = Math.min(
                  Math.max(0, flick.contentHeight - flick.height),
                  flick.contentY + step
                )
              }

              event.accepted = true
            }
          }


          ColumnLayout {
            id: popupContent
            width: flick.width - 32
            spacing: 12

            // ── Master volume ─────────────────────────────
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 6

              RowLayout {
                Layout.fillWidth: true

                Text {
                  text: root.muted ? "󰝟  Muted" : "󰕾  Volume"
                  font.family:    "Hack Nerd Font"
                  font.pixelSize: 13
                  color: root.muted ? Theme.fgMuted : Theme.fg
                }

                Item { Layout.fillWidth: true }

                // Mute toggle
                Rectangle {
                  width: 40; height: 20; radius: 10
                  color: root.muted ? Theme.slateD : Theme.purpleL
                  Behavior on color { ColorAnimation { duration: 150 } }

                  Rectangle {
                    width: 16; height: 16; radius: 8
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.muted ? 2 : parent.width - 18
                    color: root.muted ? Theme.fgMuted : Theme.purple
                    Behavior on x { NumberAnimation { duration: 150 } }
                  }

                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      root.muted = !root.muted
                      Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                    }
                    cursorShape: Qt.PointingHandCursor
                  }
                }

                Text {
                  text: root.vol + "%"
                  font.family:    Theme.font
                  font.pixelSize: 12
                  color: Theme.fgMuted
                  Layout.minimumWidth: 34
                  horizontalAlignment: Text.AlignRight
                }
              }

              // Volume slider
              Slider {
                id: masterSlider
                Layout.fillWidth: true
                from: 0; to: 100
                value: root.vol
                stepSize: 1

                onPressedChanged: {
                  root.anySliderDragging = pressed
                }

                onMoved: {
                  root.vol = value
                  master_debounce.restart()
                }

                Timer {
                  id: master_debounce
                  interval: 300
                  repeat: false
                  onTriggered: {
                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (masterSlider.value / 100).toFixed(2)])
                  }
                }

                background: Rectangle {
                  x: masterSlider.leftPadding
                  y: masterSlider.topPadding + masterSlider.availableHeight / 2 - height / 2
                  width: masterSlider.availableWidth
                  height: 4; radius: 2
                  color: Theme.slateD

                  Rectangle {
                    width: masterSlider.visualPosition * parent.width
                    height: parent.height; radius: 2
                    color: Theme.purple
                  }
                }

                // handle: Rectangle {
                //     x: masterSlider.leftPadding + masterSlider.visualPosition * (masterSlider.availableWidth - width)
                //     y: masterSlider.topPadding + masterSlider.availableHeight / 2 - height / 2
                //     width: 14; height: 14; radius: 7
                //     color: "white"
                //     border.color: Theme.purple
                //     border.width: 2
                // }
              }
            }

            // ── Divider ───────────────────────────────────
            Rectangle {
              Layout.fillWidth: true
              height: 1
              color: Theme.slateD
              visible: root.appVolumes.length > 0
            }

            // ── App volumes ───────────────────────────────
            Repeater {
              model: root.appVolumes

              ColumnLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                width: popupContent.width
                spacing: 4

                property int localVol: modelData.vol

                onModelDataChanged: {
                  console.log(modelData.icon)
                  if (!root.anySliderDragging) localVol = modelData.vol
                }

                Timer {
                  id: app_debounce
                  interval: 300
                  repeat: false
                  onTriggered: {
                    Quickshell.execDetached(["pactl", "set-sink-input-volume", modelData.id, appSlider.value + "%"])
                  }
                }


                RowLayout {
                  Layout.fillWidth: true

                  Item {
                    width: 14
                    height: 14
                    clip: true

                    Image {
                      id: img
                      width: 14; height: 14
                      anchors.centerIn: parent
                      source: Quickshell.iconPath(modelData.icon, "audio-x-generic")
                      fillMode: Image.PreserveAspectFit
                      sourceSize.width: 14
                      sourceSize.height: 14
                      smooth: true
                      visible: status === Image.Ready
                    }
                  }

                  Text {
                    width: 14; height: 14
                    visible: img.status !== Image.Ready
                    text: "󰕾"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: 11
                  } 

                  Text {
                    text: modelData.name
                    font.family:    Theme.font
                    font.pixelSize: 11
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }

                  Text {
                    text: localVol + "%"
                    font.family:    Theme.font
                    font.pixelSize: 11
                    color: Theme.fgMuted
                    Layout.minimumWidth: 34
                    horizontalAlignment: Text.AlignRight
                  }
                }

                Slider {
                  id: appSlider
                  Layout.fillWidth: true
                  from: 0; to: 100
                  value: localVol
                  stepSize: 1

                  onPressedChanged: {
                    root.anySliderDragging = pressed
                  }

                  onMoved: {
                    localVol = value
                    app_debounce.restart()
                  }

                  background: Rectangle {
                    x: appSlider.leftPadding
                    y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                    width: appSlider.availableWidth
                    height: 3; radius: 2
                    color: Theme.slateD

                    Rectangle {
                      width: appSlider.visualPosition * parent.width
                      height: parent.height; radius: 2
                      color: Theme.blue
                      border.color: Theme.blueL
                      border.width: 0
                    }
                  }

                  // handle: Rectangle {
                  //     x: appSlider.leftPadding + appSlider.visualPosition * (appSlider.availableWidth - width)
                  //     y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                  //     width: 12; height: 12; radius: 6
                  //     color: "white"
                  //     border.color: Theme.blue
                  //     border.width: 2
                  // }
                }
              }
            }

            Item { height: 4 }
          }
        }
      }
    }
  }

  // ── Bar widget ────────────────────────────────────────────
  MouseArea {
    id: volRow
    anchors.fill: parent
    onClicked: {
      if (popup.visible) {
        closeAnim.restart()
      } else {
        popup.visible = true
        refresh()
      }
    }

    onWheel: (wheel) => {
      if (wheel.angleDelta.y > 0) {
        root.vol = Math.min(100, root.vol + 5)
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "5%+"])
      } else {
        root.vol = Math.max(0, root.vol - 5)
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
      }
      osd.show(root.vol, root.muted)
    }
    cursorShape: Qt.PointingHandCursor

    Text {
      id: volText
      anchors.centerIn: parent
      text:  root.muted ? "󰝟" : (root.vol > 50 ? "󰕾" : "󰖀")
      color: root.muted ? Theme.fgMuted : Theme.purple
      font.family:    "Hack Nerd Font"
      font.pixelSize: 14
    }
  }
}

