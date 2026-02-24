import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// ── System Tray ───────────────────────────────────────────────
// Pinned items visible, overflow button for the rest
Item {
  id: root
  implicitWidth:  trayRow.implicitWidth
  implicitHeight: trayRow.implicitHeight

  readonly property int pinnedCount: 0
  readonly property var allItems:    SystemTray.items.values
  readonly property var pinnedItems: allItems.slice(0, pinnedCount)
  readonly property var overflowItems: allItems.slice(pinnedCount)
  readonly property bool hasOverflow: overflowItems.length > 0

  // ── Overflow popup ────────────────────────────────────────
  PopupWindow {
    id: overflowPopup
    visible: false
    implicitWidth:  overflowItems.length * 30 + 16
    implicitHeight: 44
    color: "transparent"
    anchor.item:    overflowBtn
    anchor.edges:   Edges.Bottom
    anchor.gravity: Edges.Bottom

    Rectangle {
      anchors.fill: parent
      radius: 10
      color:  "white"
      border.color: Theme.border
      border.width: 1

      Row {
        anchors.centerIn: parent
        spacing: 6

        Repeater {
          model: root.overflowItems

          delegate: TrayItemDelegate {
            required property SystemTrayItem modelData
            item: modelData
            onClosePopup: overflowPopup.visible = false
          }
        }
      }
    }
  }

  // ── Bar widget ────────────────────────────────────────────
  Row {
    id: trayRow
    spacing: 6

    // Pinned items
    Repeater {
      model: root.pinnedItems

      delegate: TrayItemDelegate {
        required property SystemTrayItem modelData
        item: modelData
      }
    }

    // Overflow button
    Item {
      id: overflowBtn
      visible: root.hasOverflow
      width:  20
      height: 20

      Text {
        anchors.centerIn: parent
        text:  "›"
        color: Theme.purple
        font.pixelSize: 14
        font.weight:    Font.Bold
        rotation: overflowPopup.visible ? 90 : 0
        Behavior on rotation { NumberAnimation { duration: 150 } }
        Behavior on color    { ColorAnimation  { duration: 150 } }
      }

      MouseArea {
        anchors.fill: parent
        onClicked:    overflowPopup.visible = !overflowPopup.visible
        cursorShape:  Qt.PointingHandCursor
      }
    }
  }
}

