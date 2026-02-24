import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

// ── Battery ───────────────────────────────────────────────────
Item {
  id: root
  implicitWidth:  24
  implicitHeight: 24

  property Item barItem: null

  property int    batPercent:   0
  property string batStatus:    "Unknown"
  property string batTime:      ""
  property string powerProfile: "balanced"
  property bool   recentlySent: false

  readonly property bool charging: batStatus === "Charging" || batStatus === "Full"
  readonly property bool critical: batPercent <= 15 && !charging

  property color pillColor: {
    if (root.critical) {
      return Theme.redL
    }
    if (root.charging || root.batPercent > 50) {
      return Theme.greenL
    }
    return Theme.yellowL
  }

  function refresh() {
    capacityFile.reload()
    statusFile.reload()
    getTime.running    = true
    getProfile.running = true
  }

  // ── Data ──────────────────────────────────────────────────
  FileView {
    id: capacityFile
    path: "/sys/class/power_supply/BAT1/capacity"
    watchChanges: true
    onFileChanged: reload()
    onLoadedChanged: root.batPercent = parseInt(capacityFile.text()) || 0
  }

  FileView {
    id: statusFile
    path: "/sys/class/power_supply/BAT1/status"
    watchChanges: true
    onFileChanged: reload()
    onLoadedChanged: root.batStatus = statusFile.text().trim()
  }

  Process {
    id: getTime
    command: ["sh", "-c", "acpi -b 2>/dev/null | grep -oP '\\d+:\\d+:\\d+' | head -1"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const t = this.text.trim()
        if (t) {
          const parts = t.split(":")
          const h = parseInt(parts[0])
          const m = parseInt(parts[1])
          root.batTime = h > 0 ? `${h}h ${m}m` : `${m}m`
        } else {
          root.batTime = ""
        }
      }
    }
  }

  Process {
    id: getProfile
    command: ["powerprofilesctl", "get"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.recentlySent) root.powerProfile = this.text.trim()
      }
    }
  }

  // Cooldown to block sync after setting profile
  Timer {
    id: profileCooldown
    interval: 1000
    repeat: false
    onTriggered: root.recentlySent = false
  }

  Timer {
    interval: 30000; running: true; repeat: true
    onTriggered: refresh()
  }

  // Blink when critical
  SequentialAnimation on opacity {
    running: root.critical
    loops:   Animation.Infinite
    NumberAnimation { to: 0.3; duration: 500 }
    NumberAnimation { to: 1.0; duration: 500 }
    onStopped: root.opacity = 1
  }

  // ── Popup ─────────────────────────────────────────────────
  PopupWindow {
    id: popup
    visible: false
    implicitWidth:  240
    implicitHeight: 260

    color: "transparent"
    anchor.item:    barItem ?? batRow
    anchor.edges:   Edges.Bottom
    anchor.gravity: Edges.Bottom

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
        to: 300
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
      anchors.left: parent.left
      anchors.right: parent.right
      color:  Theme.bg
      clip: true
      radius: 0
      border.width: 0


      layer.enabled: true

      ColumnLayout {
        id: popupCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12

        // ── Status header ─────────────────────────────
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: {
              if (root.charging)        return "󰂄"
              if (root.batPercent > 90) return "󰁹"
              if (root.batPercent > 70) return "󰂁"
              if (root.batPercent > 50) return "󰁿"
              if (root.batPercent > 30) return "󰁽"
              if (root.batPercent > 15) return "󰁻"
              return "󰁺"
            }
            font.family:    "Hack Nerd Font"
            font.pixelSize: 28
            color: root.critical ? Theme.red : root.charging ? Theme.green : Theme.yellowD
          }

          ColumnLayout {
            spacing: 2
            Text {
              text: root.batPercent + "%  ·  " + root.batStatus
              font.family:    Theme.font
              font.pixelSize: 13
              font.weight:    Font.SemiBold
              color: Theme.fg
            }
            Text {
              visible: root.batTime !== ""
              text: root.charging ? "Full in " + root.batTime : root.batTime + " remaining"
              font.family:    Theme.font
              font.pixelSize: 11
              color: Theme.fgMuted
            }
          }
        }

        // ── Battery bar ───────────────────────────────
        Rectangle {
          Layout.fillWidth: true
          height: 6; radius: 3
          color: Theme.slateD

          Rectangle {
            width: parent.width * (root.batPercent / 100)
            height: parent.height; radius: 3
            color: root.critical ? Theme.red : root.charging ? Theme.green : Theme.purple
            Behavior on width { NumberAnimation { duration: 300 } }
          }
        }

        // ── Divider ───────────────────────────────────
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.slateD }

        // ── Power profiles ────────────────────────────
        Text {
          text: "Power Profile"
          font.family:    Theme.font
          font.pixelSize: 11
          color: Theme.fgMuted
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Repeater {
            model: [
              { id: "power-saver",  label: "Saver",    icon: "󰌪" },
              { id: "balanced",     label: "Balanced", icon: "󰗑" },
              { id: "performance",  label: "Perf",     icon: "󱐋" },
            ]

            Rectangle {
              required property var modelData
              Layout.fillWidth: true
              height: 36; radius: 8
              color: root.powerProfile === modelData.id ? Theme.purpleL : Theme.slate
              border.color: root.powerProfile === modelData.id ? Theme.purple : "transparent"
              border.width: 1
              Behavior on color { ColorAnimation { duration: 150 } }

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 1

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: modelData.icon
                  font.family:    "Hack Nerd Font"
                  font.pixelSize: 13
                  color: root.powerProfile === modelData.id ? Theme.purple : Theme.fgMuted
                }
                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: modelData.label
                  font.family:    Theme.font
                  font.pixelSize: 9
                  color: root.powerProfile === modelData.id ? Theme.purple : Theme.fgMuted
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.powerProfile = modelData.id
                  root.recentlySent = true
                  profileCooldown.restart()
                  Quickshell.execDetached(["powerprofilesctl", "set", modelData.id])
                }
              }
            }
          }
        }

        Item { height: 2 }
      }
    }
  }

  // ── Bar widget ────────────────────────────────────────────
  MouseArea {
    id: batRow
    anchors.fill: parent
    onClicked: {
      if (popup.visible) {
        closeAnim.restart()
      } else {
        popup.visible = true
        refresh()
      }
    }
    cursorShape: Qt.PointingHandCursor

    Text {
      anchors.centerIn: parent
      text: {
        if (root.charging)        return "󰂄"
        if (root.batPercent > 90) return "󰁹"
        if (root.batPercent > 70) return "󰂁"
        if (root.batPercent > 50) return "󰁿"
        if (root.batPercent > 30) return "󰁽"
        if (root.batPercent > 15) return "󰁻"
        return "󰁺"
      }
      color: {
        if (root.critical) {
          return Theme.red
        }
        if (root.charging || root.batPercent > 50) {
          return Theme.green
        }
        return Theme.yellowD
      }
      font.family:    "Hack Nerd Font"
      font.pixelSize: 14
    }
  }
}

