import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts


// ── Bar ───────────────────────────────────────────────────────
PanelWindow {
  id: root

  anchors.top:   true
  anchors.left:  true
  anchors.right: true

  implicitHeight: Theme.barHeight + Theme.barMarginTop * 2
  color: Theme.bg

  exclusionMode: ExclusionMode.Normal
  exclusiveZone: Theme.barHeight + Theme.barMarginTop

  Item {
    anchors.fill:      parent
    anchors.topMargin: Theme.barMarginTop

    VolumeOSD {
      id: osd
    }

    // ── Left pill — Workspaces ────────────────────────────
    Rectangle {
      id: leftPill
      anchors.left:           parent.left
      anchors.leftMargin:     Theme.barMarginH

      height: Theme.barHeight
      radius: Theme.barHeight / 4
      color:  "white"

      // Soft drop shadow
      layer.enabled: true
      layer.effect: null

      implicitWidth: workspacesRow.implicitWidth + Theme.pillPadH * 2

      WorkspacesModule {
        id: workspacesRow
        anchors.centerIn: parent
      }
    }

    // ── Center pill — Clock ───────────────────────────────
    Rectangle {
      id: centerPill
      anchors.horizontalCenter: parent.horizontalCenter

      height: Theme.barHeight
      radius: Theme.barHeight / 4
      color:  Theme.greenL

      implicitWidth: clockModule.implicitWidth + Theme.pillPadH * 2

      ClockModule {
        id: clockModule
        anchors.centerIn: parent
        Component.onCompleted: barItem = centerPill
      }
    }

    RowLayout {
      id: rightPill
      anchors.right: parent.right
      anchors.rightMargin: Theme.barMarginH
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      Rectangle {
        id: trayPill
        height: Theme.barHeight
        radius: Theme.barHeight / 4
        color: Theme.purpleL
        implicitWidth: trayRow.implicitWidth + Theme.pillPadH * 2
        RowLayout {
          id: trayRow
          anchors.centerIn: parent
          spacing: 10
          TrayModule {
            Component.onCompleted: barItem = trayPill
          }
          VolumeModule {
            Component.onCompleted: barItem = trayPill
          }
        }
      }

      Rectangle {
        id: batteryPill
        height: Theme.barHeight
        radius: Theme.barHeight / 4
        color: batteryModule.pillColor
        implicitWidth: batteryRow.implicitWidth + Theme.pillPadH
        RowLayout {
          id: batteryRow
          anchors.centerIn: parent
          BatteryModule {
            id: batteryModule
            Component.onCompleted: barItem = batteryPill
          }
        }
      }
    }

  }
}

