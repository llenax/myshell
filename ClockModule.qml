import Quickshell
import Quickshell.Io
import QtQuick

// ── Clock ─────────────────────────────────────────────────────
Item {
  implicitWidth:  timeText.implicitWidth
  implicitHeight: timeText.implicitHeight

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
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
}

