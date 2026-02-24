//@ pragma UseQApplication

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick

// ── Main entry point ──────────────────────────────────────────
// Spawns a bar on every connected screen
Scope {
  Variants {
    model: Quickshell.screens
    delegate: Bar {
      required property var modelData
      screen: modelData
    }
  }
}
