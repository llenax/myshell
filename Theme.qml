pragma Singleton
import QtQuick

// ── Theme ─────────────────────────────────────────────────────
// Matches waybar & hyprland pastel color scheme
QtObject {
  // Base
  readonly property color bg:      "#ffffff"
  readonly property color bgPill:  "#ffffff"
  readonly property color border:  "#14000000"
  readonly property color shadow:  "#1f000000"

  // Text
  readonly property color fg:      "#1a1a2e"
  readonly property color fgMuted: "#64748b"

  // Accent colors — same as waybar modules
  readonly property color purple:  "#7c3aed"
  readonly property color purpleL: "#ede9fe"
  readonly property color purpleLL: "#b197fc"
  readonly property color blue:    "#1d4ed8"
  readonly property color blueL:   "#eff6ff"
  readonly property color green:   "#15803d"
  readonly property color greenL:  "#f0fdf4"
  readonly property color yellow:  "#F8DE7E"
  readonly property color yellowL: "#fef9c3"
  readonly property color yellowD: "#EFBF04"
  readonly property color red:     "#b91c1c"
  readonly property color redL:    "#fee2e2"
  readonly property color slate:   "#f1f5f9"
  readonly property color slateD:  "#e2e8f0"

  // Font
  readonly property string font:   "Hack Nerd Font"
  readonly property int fontSize:  12

  // Layout
  readonly property int barHeight:    32
  readonly property int pillRadius:   10
  readonly property int pillPadH:     14
  readonly property int pillPadV:     4
  readonly property int pillMargin:   3
  readonly property int barMarginTop: 4
  readonly property int barMarginH:   20
}

