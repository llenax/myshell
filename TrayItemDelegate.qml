import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

// ── TrayItemDelegate ──────────────────────────────────────────
// Single tray icon with left/right click and tooltip
Item {
  id: root
  width:  20
  height: 20

  required property SystemTrayItem item
  signal closePopup()

  // Tooltip
  property string tooltipText: root.item?.tooltip?.title || root.item?.title || ""


  Image {
    anchors.fill: parent
    source:       root.item?.icon ?? ""
    smooth:       true
    mipmap:       true
  }

  // Hover tooltip
  Rectangle {
    id: tooltip
    visible:      hov.hovered && root.tooltipText !== ""
    anchors.bottom: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 4
    color:        Theme.fg
    radius:       4
    width:        tooltipLabel.implicitWidth + 10
    height:       tooltipLabel.implicitHeight + 6

    Text {
      id: tooltipLabel
      anchors.centerIn: parent
      text:       root.tooltipText
      color:      "white"
      font.family:    Theme.font
      font.pixelSize: 10
    }
  }

  HoverHandler { id: hov }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        root.item.activate()
      } else {
        root.item.secondaryActivate()
      }
      root.closePopup()
    }
    cursorShape: Qt.PointingHandCursor
  }
}

