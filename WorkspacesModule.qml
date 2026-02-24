import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// ── Workspaces ────────────────────────────────────────────────
Item {
  id: root

  readonly property int minWs: 5
  readonly property int wsCount: {
    let max = activeWsId;
    for (const win of HyprlandData.windowList) {
      if (win.workspace?.id > max)
      max = win.workspace.id;
    }
    return Math.max(minWs, max);
  }
  readonly property int buttonSize:  32
  readonly property int spacing:     0
  readonly property int activeWsId:  Hyprland.focusedWorkspace?.id ?? 1
  readonly property int activeIndex: activeWsId - 1

  implicitWidth:  wsCount * buttonSize
  implicitHeight: buttonSize

  // ── Layer 1: Occupied background rects ───────────────────
  Repeater {
    model: root.wsCount

    Rectangle {
      required property int index
      readonly property int  wsId:      index + 1
      readonly property bool isActive:  root.activeWsId === wsId
      readonly property var  winData: {
        HyprlandData.windowList
        return HyprlandData.biggestWindowForWorkspace(wsId)
      }
      readonly property bool occupied:  winData !== null

      // Check neighbours — merge if adjacent is occupied (active included)
      readonly property bool prevOccupied: {
        HyprlandData.windowList
        return index > 0 && HyprlandData.biggestWindowForWorkspace(wsId - 1) !== null
      }
      readonly property bool nextOccupied: {
        HyprlandData.windowList
        return index < root.wsCount - 1 && HyprlandData.biggestWindowForWorkspace(wsId + 1) !== null
      }

      z: 1
      x: index * root.buttonSize
      width:  root.buttonSize
      height: root.buttonSize

      // Merge corners with adjacent occupied workspaces
      readonly property real innerR: 0
      readonly property real outerR: root.buttonSize

      topLeftRadius:     prevOccupied ? innerR : outerR
      bottomLeftRadius:  prevOccupied ? innerR : outerR
      topRightRadius:    nextOccupied ? innerR : outerR
      bottomRightRadius: nextOccupied ? innerR : outerR

      color:   Theme.slateD
      opacity: occupied ? 1 : 0

      Behavior on opacity          { NumberAnimation { duration: 180 } }
      Behavior on topLeftRadius    { NumberAnimation { duration: 120 } }
      Behavior on bottomLeftRadius { NumberAnimation { duration: 120 } }
      Behavior on topRightRadius   { NumberAnimation { duration: 120 } }
      Behavior on bottomRightRadius{ NumberAnimation { duration: 120 } }
    }
  }

  // ── Layer 2: Active indicator ────────────────────────────
  Rectangle {
    id: indicator
    z: 2
    width:  root.buttonSize
    height: root.buttonSize
    radius: root.buttonSize
    color:  Qt.rgba(124/255, 58/255, 237/255, 0.18)

    x: root.activeIndex * root.buttonSize
    Behavior on x { SmoothedAnimation { velocity: 500 } }

    Rectangle {
      z: 2
      width:  root.buttonSize
      height: root.buttonSize
      radius: root.buttonSize
      color: parent.color
      border.color:  Qt.rgba(124/255, 58/255, 237/255, 0.08)
      border.width: 2

      Rectangle {
        z: 2
        width:  root.buttonSize
        height: root.buttonSize
        radius: root.buttonSize
        color: parent.color
        border.color:  Qt.rgba(124/255, 58/255, 237/255, 0.04)
        border.width: 2


        Rectangle {
          z: 2
          width:  root.buttonSize
          height: root.buttonSize
          radius: root.buttonSize
          color: parent.color
          border.color:  Qt.rgba(124/255, 58/255, 237/255, 0.02)
          border.width: 2
        }
      }
    }
  }

  // ── Layer 3: Icons / dots ────────────────────────────────
  Row {
    spacing: 0
    z: 3

    Repeater {
      model: root.wsCount

      Item {
        id: btn
        required property int index
        readonly property int  wsId:      index + 1
        readonly property bool isActive:  root.activeWsId === wsId
        readonly property var  winData: {
          HyprlandData.windowList
          return HyprlandData.biggestWindowForWorkspace(wsId)
        }
        readonly property bool hasWindow: winData !== null
        readonly property string appIcon: winData?.class
        ? Quickshell.iconPath(AppSearch.guessIcon(winData.class), "image-missing")
        : ""
        readonly property bool hasIcon:   appIcon !== ""
        && !appIcon.includes("image://icon/image-missing")

        width:  root.buttonSize
        height: root.buttonSize

        // App icon
        Image {
          anchors.centerIn: parent
          width:   btn.hasIcon ? 16 : 0
          height:  btn.hasIcon ? 16 : 0
          source:  btn.appIcon
          visible: btn.hasIcon
          smooth:  true
          mipmap:  true
          Behavior on width  { NumberAnimation { duration: 150 } }
          Behavior on height { NumberAnimation { duration: 150 } }
        }

        // Dot — occupied but no icon
        Rectangle {
          anchors.centerIn: parent
          visible: btn.hasWindow && !btn.hasIcon
          width:  6; height: 6; radius: 3
          color: btn.isActive ? Theme.purple : Qt.rgba(124/255, 58/255, 237/255, 0.5)
        }

        // Dot — empty workspace
        Rectangle {
          anchors.centerIn: parent
          visible: !btn.hasWindow
          width:  4; height: 4; radius: 2
          color: Theme.slateD
        }

        MouseArea {
          anchors.fill: parent
          onClicked:    Hyprland.dispatch("workspace " + btn.wsId)
          cursorShape:  Qt.PointingHandCursor
        }
      }
    }
  }
}

