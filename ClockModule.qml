import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
  implicitWidth:  timeText.implicitWidth
  implicitHeight: timeText.implicitHeight

  property Item barItem: null

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  // ── Calendar Popup ────────────────────────────────────────
  PopupWindow {
    id: popup
    visible: false
    implicitWidth: 260
    implicitHeight: 300
    color: "transparent"
    anchor.item:    barItem ?? timeText
    anchor.edges:   Edges.Bottom
    anchor.gravity: Edges.Bottom

    onWindowConnected: focusGrab.active = true
    onVisibleChanged: {
      if (visible) {
        popupRect.height = 0
        popupRect.opacity = 0
        openAnim.restart()
        calOffset = 0
      } else {
        focusGrab.active = false
      }
    }

    HyprlandFocusGrab {
      id: focusGrab
      windows: [popup]
      onCleared: if (popup.visible && !closeAnim.running) closeAnim.restart()
    }

    ParallelAnimation {
      id: openAnim
      NumberAnimation { target: popupRect; property: "height"; to: 280; duration: 220; easing.type: Easing.OutCubic }
      NumberAnimation { target: popupRect; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
    }
    ParallelAnimation {
      id: closeAnim
      NumberAnimation { target: popupRect; property: "height"; to: 0; duration: 160; easing.type: Easing.InCubic }
      NumberAnimation { target: popupRect; property: "opacity"; to: 0; duration: 140; easing.type: Easing.InCubic }
      onFinished: popup.visible = false
    }

    // how many months offset from current
    property int calOffset: 0

    property var displayDate: {
      if (!clock.date) return new Date()
      const d = new Date(clock.date)
      if (isNaN(d.getTime())) return new Date()
      d.setDate(1)
      d.setMonth(d.getMonth() + popup.calOffset)
      return d
    }

    property int displayYear:  displayDate ? displayDate.getFullYear() : clock.date.getFullYear()
    property int displayMonth: displayDate ? displayDate.getMonth() : clock.date.getMonth()

    property int daysInMonth: displayDate ? new Date(displayYear, displayMonth + 1, 0).getDate() : 0
    property int firstWeekday: displayDate ? new Date(displayYear, displayMonth, 0).getDay() : 0

    property int todayDate:  clock.date ? clock.date.getDate() : 0
    property int todayMonth: clock.date ? clock.date.getMonth() : -1
    property int todayYear:  clock.date ? clock.date.getFullYear() : -1

    Rectangle {
      id: popupRect
      anchors.top: parent.top
      anchors.topMargin: 2
      anchors.left: parent.left
      anchors.right: parent.right
      height: 0
      clip: true
      color: Theme.bg
      opacity: 0
      radius: 0

      Rectangle {
        width: parent.width
        height: 2
        color: Theme.purple
      }


      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // ── Month header ──────────────────────────────
        RowLayout {
          Layout.fillWidth: true

          Text {
            text: "‹"
            font.pixelSize: 16
            color: Theme.fgMuted
            MouseArea {
              anchors.fill: parent
              onClicked: popup.calOffset--
              cursorShape: Qt.PointingHandCursor
            }
          }

          Item { Layout.fillWidth: true }

          Text {
            text: Qt.formatDate(popup.displayDate, "MMMM yyyy")
            font.family:    Theme.font
            font.pixelSize: 13
            font.weight:    Font.SemiBold
            color: Theme.fg
          }

          Item { Layout.fillWidth: true }

          Text {
            text: "›"
            font.pixelSize: 16
            color: Theme.fgMuted
            MouseArea {
              anchors.fill: parent
              onClicked: popup.calOffset++
              cursorShape: Qt.PointingHandCursor
            }
          }
        }

        // ── Day headers ───────────────────────────────
        Grid {
          Layout.fillWidth: true
          columns: 7
          columnSpacing: 0

          Repeater {
            model: ["Mo","Tu","We","Th","Fr","Sa", "Su"]
            Text {
              width: (260 - 28) / 7
              horizontalAlignment: Text.AlignHCenter
              text: modelData
              font.family:    Theme.font
              font.pixelSize: 10
              color: Theme.fgMuted
            }
          }
        }

        // ── Day grid ──────────────────────────────────
        Grid {
          Layout.fillWidth: true
          columns: 7
          columnSpacing: 0
          rowSpacing: 2

          // empty cells before first day
          Repeater {
            model: popup.firstWeekday
            Item { width: (260 - 28) / 7; height: 24 }
          }

          // day cells
          Repeater {
            model: popup.daysInMonth

            Rectangle {
              required property int index
              width: (260 - 28) / 7
              height: 24
              radius: 6
              property bool isToday: {
                if (!popup.todayDate || popup.todayMonth === undefined || popup.todayYear === undefined)  {
                  return false
                }
                return (index + 1) === popup.todayDate &&
                  popup.displayMonth === popup.todayMonth &&
                  popup.displayYear  === popup.todayYear
              }
              color: isToday ? Theme.purple : "transparent"

              Text {
                anchors.centerIn: parent
                text: index + 1
                font.family:    Theme.font
                font.pixelSize: 11
                font.weight:    isToday ? 600 : 400
                color: isToday ? "white" : Theme.fg
              }
            }
          }
        }

        Item { Layout.fillWidth: true }
      }
    }
  }

  Text {
    id: timeText
    anchors.centerIn: parent
    text: Qt.formatDateTime(clock.date, "hh:mm  ddd dd MMM")
    color: Theme.green
    font.family:    Theme.font
    font.pixelSize: Theme.fontSize
    font.weight:    Font.SemiBold
    font.letterSpacing: 0.5
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      if (popup.visible) closeAnim.restart()
      else {
        popup.calOffset = 0
        popup.visible = true
      }
    }
    cursorShape: Qt.PointingHandCursor
  }
}
