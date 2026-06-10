pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

// Shared, preloaded list of installed desktop apps with resolved icon paths.
// Both the full Launcher and the bar's Apps dropdown read from here, so the
// expensive scan (find + per-app icon-resolve.sh) runs ONCE at startup instead
// of every time a menu opens — which is what made the icons visibly re-populate.
//
// The list lives in memory for the session and is rebuilt only when the icon
// theme flips (mocha↔latte swaps Papirus-Dark↔Papirus, so paths change).
QtObject {
    id: appList

    property var apps: []                // [{ name, exec, icon, category }]
    property var categories: ["All"]
    property bool loaded: false
    property bool loading: false

    // Papirus-Dark on dark (mocha), Papirus on light (latte) — matches sync-theme.sh.
    readonly property string iconTheme: Colors.darkMode ? "Papirus-Dark" : "Papirus"

    // The running quickshell process keeps its launch-time ICON_THEME env, so we
    // pass the theme explicitly and rebuild when it changes rather than trusting env.
    onIconThemeChanged: if (loaded || loading) reload()

    function ensureLoaded() { if (!loaded && !loading) reload() }

    function reload() {
        loading = true
        loader.parsed = []
        loader.command = ["bash", "-c", loader.script, "_", iconTheme]
        loader.running = true
    }

    function buildCategories() {
        const seen = new Set()
        apps.forEach(a => { if (a.category) seen.add(a.category) })
        categories = ["All", ...Array.from(seen).sort()]
    }

    // Preload as soon as the singleton is instantiated (Bar.qml touches it at startup).
    Component.onCompleted: ensureLoaded()

    // Live updates: watch the application directories so installing or removing
    // an app (pacman, yay, flatpak, or a manual .desktop drop) refreshes the
    // list without restarting quickshell. A package op touches many files at
    // once, so we debounce and rebuild once the filesystem settles.
    property Timer refreshDebounce: Timer {
        interval: 1500
        onTriggered: {
            if (appList.loading) { restart(); return }  // wait out an in-flight scan
            appList.reload()
        }
    }

    property Process watcher: Process {
        running: true
        // Only watch dirs that exist (inotifywait errors on a missing path),
        // then monitor for entries appearing, disappearing, or being rewritten.
        command: ["bash", "-c",
            "dirs=(); for d in /usr/share/applications " +
            "\"$HOME/.local/share/applications\" " +
            "/var/lib/flatpak/exports/share/applications " +
            "\"${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports/share/applications\"; do " +
            "[ -d \"$d\" ] && dirs+=(\"$d\"); done; " +
            "[ ${#dirs[@]} -eq 0 ] && exit 0; " +
            "exec inotifywait -mq -e create -e delete -e moved_to -e moved_from -e close_write \"${dirs[@]}\""
        ]
        stdout: SplitParser {
            onRead: appList.refreshDebounce.restart()
        }
    }

    property Process loader: Process {
        id: loader
        property var parsed: []

        // $1 = icon theme to resolve against. Games keep their original icon
        // (mode=original); everything else is recolored to the active theme.
        readonly property string script:
            "theme=\"${1:-Papirus-Dark}\"; " +
            "find /usr/share/applications ~/.local/share/applications " +
            "/var/lib/flatpak/exports/share/applications " +
            "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports/share/applications " +
            "-name '*.desktop' 2>/dev/null | sort -u | " +
            "xargs -I{} awk 'BEGIN{n=\"\";e=\"\";i=\"\";c=\"\";nd=0;nt=0} " +
            "/\\[Desktop Entry\\]/{nt=1;next} /^\\[/{nt=0} " +
            "nt&&/^Name=/{n=substr($0,index($0,\"=\")+1)} " +
            "nt&&/^Exec=/{e=substr($0,index($0,\"=\")+1)} " +
            "nt&&/^Icon=/{i=substr($0,index($0,\"=\")+1)} " +
            "nt&&/^Categories=/{c=substr($0,index($0,\"=\")+1)} " +
            "nt&&/^NoDisplay=true/{nd=1} " +
            "END{if(!nd&&n!=\"\"&&e!=\"\")print n\"|\"e\"|\"i\"|\"c}' {} | sort -u | " +
            "while IFS='|' read -r name exec icon cats; do " +
            "  cat=$(echo \"$cats\" | tr ';' '\\n' | grep -Ew " +
            "'AudioVideo|Audio|Video|Graphics|Office|Game|Network|Science|Education|Development|System|Utility' " +
            "| head -1); " +
            "  case $cat in " +
            "    AudioVideo|Audio|Video) cat=Media ;; " +
            "    Game) cat=Games ;; " +
            "    Network) cat=Internet ;; " +
            "    Utility) cat=Utilities ;; " +
            "    *) [ -z \"$cat\" ] && cat=Other ;; " +
            "  esac; " +
            "  resolved=''; " +
            "  mode=theme; [[ \";${cats};\" == *\";Game;\"* ]] && mode=original; " +
            "  if [ -n \"$icon\" ]; then " +
            "    resolved=$(\"$HOME/dotfiles/scripts/icon-resolve.sh\" \"$icon\" \"$theme\" \"$mode\"); " +
            "  fi; " +
            "  echo \"${name}|${exec}|${resolved}|${cat}\"; " +
            "done"

        stdout: SplitParser {
            onRead: line => {
                const p = line.split("|")
                if (p.length >= 2 && p[0])
                    loader.parsed.push({
                        name: p[0], exec: p[1],
                        icon: p[2] || "", category: p[3] || "Other"
                    })
            }
        }

        onRunningChanged: {
            if (!running) {
                if (parsed.length > 0) {
                    appList.apps = parsed.sort((a, b) => a.name.localeCompare(b.name))
                    parsed = []
                    appList.buildCategories()
                }
                appList.loaded = true
                appList.loading = false
            }
        }
    }
}
