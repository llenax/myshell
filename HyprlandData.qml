pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// ── HyprlandData ──────────────────────────────────────────────
// Provides window/workspace data via hyprctl JSON polling.
// Updates on every Hyprland event for live reactivity.
Singleton {
  id: root

  property var windowList:      []
  property var windowByAddress: ({})
  property var workspaces:      []
  property var workspaceById:   ({})
  property var activeWorkspace: null

  // Returns the biggest window (by area) in a workspace
  function biggestWindowForWorkspace(workspaceId) {
    const wins = root.windowList.filter(w => w.workspace.id == workspaceId)
    return wins.reduce((maxWin, win) => {
      const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0)
      const winArea = (win?.size?.[0]  ?? 0) * (win?.size?.[1]  ?? 0)
      return winArea > maxArea ? win : maxWin
    }, null)
  }

  function updateAll() {
    getClients.running   = true
    getWorkspaces.running = true
    getActiveWorkspace.running = true
  }

  Component.onCompleted: updateAll()

  // Re-poll on every Hyprland event
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      // Skip layer/screencast events — they don't affect windows
      if (["openlayer", "closelayer", "screencast"].includes(event.name)) return
      updateAll()
    }
  }

  Process {
    id: getClients
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      id: clientsCollector
      onStreamFinished: {
        root.windowList = JSON.parse(clientsCollector.text)
        let tmp = {}
        for (const win of root.windowList) tmp[win.address] = win
        root.windowByAddress = tmp
      }
    }
  }

  Process {
    id: getWorkspaces
    command: ["hyprctl", "workspaces", "-j"]
    stdout: StdioCollector {
      id: workspacesCollector
      onStreamFinished: {
        const raw = JSON.parse(workspacesCollector.text)
        root.workspaces = raw.filter(ws => ws.id >= 1 && ws.id <= 100)
        let tmp = {}
        for (const ws of root.workspaces) tmp[ws.id] = ws
        root.workspaceById = tmp
      }
    }
  }

  Process {
    id: getActiveWorkspace
    command: ["hyprctl", "activeworkspace", "-j"]
    stdout: StdioCollector {
      id: activeWorkspaceCollector
      onStreamFinished: {
        root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text)
      }
    }
  }
}

