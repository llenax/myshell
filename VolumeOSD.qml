import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: osd
  visible: false
  implicitWidth: 220
  implicitHeight: 56
  color: "transparent"

  anchors.bottom: true

  margins.bottom: 80

  exclusionMode: ExclusionMode.Ignore

  property int vol: 0
  property bool muted: false

  function show(v, m) {
    vol = v ?? 0
    muted = m ?? false
    osdRect.opacity = 1
    visible = true
    hideTimer.restart()
  }

  Timer {
    id: hideTimer
    interval: 1500
    repeat: false
    onTriggered: fadeOut.restart()
  }

  NumberAnimation {
    id: fadeOut
    target: osdRect
    property: "opacity"
    to: 0
    duration: 200
    easing.type: Easing.InCubic
    onFinished: osd.visible = false
  }

  Rectangle {
    id: osdRect
    anchors.fill: parent
    radius: 16
    color: Theme.bg
    opacity: 0

    RowLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      Text {
        text: osd.muted ? "󰝟" : (osd.vol > 50 ? "󰕾" : "󰖀")
        font.family: "Hack Nerd Font"
        font.pixelSize: 18
        color: Theme.fg
      }

      Rectangle {
        Layout.fillWidth: true
        height: 4
        radius: 2
        color: Theme.slateD

        Rectangle {
          width: parent.width * (osd.vol / 100)
          height: parent.height
          radius: 2
          color: osd.muted ? Theme.fgMuted : Theme.purple
          Behavior on width { NumberAnimation { duration: 80 } }
        }
      }

      Text {
        text: osd.vol + "%"
        font.family: Theme.font
        font.pixelSize: 12
        color: Theme.fgMuted
        Layout.minimumWidth: 34
        horizontalAlignment: Text.AlignRight
      }
    }
  }
}
