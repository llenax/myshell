import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick

Item {
  id: root
  width: 20
  height: 20

  required property SystemTrayItem item
  signal closePopup()

  QsMenuAnchor {
    id: menuAnchor
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    menu: root.item.menu
  }

  Image {
    anchors.centerIn: parent
    width: 16; height: 16
    source: root.item.icon
    sourceSize.width: 16
    sourceSize.height: 16
    fillMode: Image.PreserveAspectFit
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        menuAnchor.open()
      } else {
        root.item.activate()
        root.closePopup()
      }
    }
  }
}
