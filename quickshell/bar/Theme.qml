pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Light/dark palette shared by the bar, its control panel and the runner.
// The mode comes from a one-word file ("dark" or "light") that mango's
// wallpaper.sh rewrites whenever it switches wallpapers.
Singleton {
	id: root

	readonly property string stateFile: (Quickshell.env("XDG_RUNTIME_DIR") ?? "/tmp") + "/happybar_theme"
	readonly property bool dark: modeFile.text().trim() === "dark"

	FileView {
		id: modeFile
		path: root.stateFile
		blockLoading: true
		watchChanges: true
		printErrors: false
		onFileChanged: reload()
	}

	// Light mode is the original look (dark bar, light pills); dark mode inverts it.
	readonly property int fade: 1500

	property color bar: dark ? "#e9e6df" : "#101014"            // bar / panel / runner background
	property color barInk: dark ? "#101014" : "#f2efef"         // text sitting directly on the bar
	property color barHover: dark ? "#d3cfcf" : "#3a3a42"       // list highlight on the bar
	property color pill: dark ? "#101014" : "#d3cfcf"           // widget pills and tiles
	property color ink: dark ? "#e9e6df" : "#101014"            // text and icons on pills
	property color tileActive: dark ? "#2e2e35" : "#f2efef"     // toggled-on round buttons
	property color tileHover: dark ? "#33333b" : "#bdb8b8"      // hovered buttons
	property color track: dark ? "#3a3a42" : "#a9a4a4"          // slider track
	property color dim: dark ? "#8a8585" : "#8a8585"            // disabled icons
	property color subInk: dark ? "#b5b0ab" : "#4a4a50"         // secondary text on pills

	Behavior on bar { ColorAnimation { duration: root.fade } }
	Behavior on barInk { ColorAnimation { duration: root.fade } }
	Behavior on barHover { ColorAnimation { duration: root.fade } }
	Behavior on pill { ColorAnimation { duration: root.fade } }
	Behavior on ink { ColorAnimation { duration: root.fade } }
	Behavior on tileActive { ColorAnimation { duration: root.fade } }
	Behavior on tileHover { ColorAnimation { duration: root.fade } }
	Behavior on track { ColorAnimation { duration: root.fade } }
	Behavior on subInk { ColorAnimation { duration: root.fade } }
}
