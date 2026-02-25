pragma Singleton
import Quickshell
import QtQuick

// ── AppSearch ─────────────────────────────────────────────────
// Adapted from end-4/dots-hyprland — guesses icon name for a
// window class/appId string using progressively looser heuristics.
// Stripped of Fuzzy/Levendist/Config dependencies.
QtObject {
  id: root

  // Known class → icon name substitutions
  property var substitutions: ({
    "code-url-handler":  "visual-studio-code",
    "Code":              "visual-studio-code",
    "gnome-tweaks":      "org.gnome.tweaks",
    "pavucontrol-qt":    "pavucontrol",
    "footclient":        "foot",
    "kitty":             "kitty",
  })

  property var regexSubstitutions: [
    { regex: /^steam_app_(\d+)$/, replace: "steam_icon_$1" },
    { regex: /Minecraft.*/,       replace: "minecraft" },
    { regex: /.*polkit.*/,        replace: "system-lock-screen" },
    { regex: /gcr.prompter/,      replace: "system-lock-screen" },
  ]

  function iconExists(iconName) {
    if (!iconName || iconName.length === 0) return false
    const path = Quickshell.iconPath(iconName, true)
    return path.length > 0 && !iconName.includes("image-missing")
  }

  function guessIcon(str) {
    if (!str || str.length === 0) return "application-x-executable"

    const entry = DesktopEntries.byId(str)
    if (entry) return entry.icon

    if (substitutions[str]) return substitutions[str]

    if (iconExists(str)) { return str }

    const lower = str.toLowerCase()
    if (iconExists(lower)) { return lower }

    const heuristic = DesktopEntries.heuristicLookup(str)
    if (heuristic) return heuristic.icon

    return "application-x-executable"
  }
}

