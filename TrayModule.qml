import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

// ── System Tray ───────────────────────────────────────────────
// Pinned items visible, overflow button for the rest
Item {
  id: root
  implicitWidth:  trayRow.implicitWidth
  implicitHeight: trayRow.implicitHeight

  property Item barItem: null

  readonly property int pinnedCount: 0
  readonly property var allItems:    SystemTray.items.values
  readonly property var pinnedItems: allItems.slice(0, pinnedCount)
  readonly property var overflowItems: allItems.slice(pinnedCount)
  readonly property bool hasOverflow: overflowItems.length > 0

  onAllItemsChanged: console.log("tray items:", allItems.length, allItems.map(i => i.id))

  // ── Overflow popup ────────────────────────────────────────
  PopupWindow {
    id: popup
    visible: false
    implicitWidth:  overflowItems.length * 30 + 16
    implicitHeight: 44
    color: "transparent"
    anchor.item:    barItem ?? overflowBtn
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
      active: popup.visible
      onCleared: {
        if (popup.visible && !closeAnim.running) closeAnim.restart()
      }
    }

    ParallelAnimation {
      id: openAnim
      NumberAnimation {
        target: popupRect
        property: "height"
        to: 46
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

      Row {
        anchors.centerIn: parent
        spacing: 6

        Repeater {
          model: root.overflowItems

          delegate: TrayItemDelegate {
            required property SystemTrayItem modelData
            item: modelData
            onMenuOpened: focusGrab.active = false
            onMenuClosed: focusGrab.active = true
            onClosePopup: closeAnim.restart()
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
        rotation: popup.visible ? 90 : 0
        Behavior on rotation { NumberAnimation { duration: 150 } }
        Behavior on color    { ColorAnimation  { duration: 150 } }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (popup.visible) {
            closeAnim.restart()
          } else {
            popup.visible = true
          }
        }
        cursorShape:  Qt.PointingHandCursor
      }
    }
  }
}

