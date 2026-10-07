//@ pragma UseQApplication
// Bar.qml
import Quickshell
import QtQuick
import Quickshell.Services.Pipewire as Pw

Scope {
	PanelWindow {
		property bool cpOpen: false
		// true while the control panel is on screen, including its open/close animation
		property bool cpShown: false
		// side margin scales with screen width (48 on wide screens, tighter on laptops)
		readonly property int sideMargin: Math.round(Math.max(8, Math.min(48, (screen ? screen.width : 1920) * 0.025)))

		id: my_bar

		// Always the main screen: the one named in happybar_main_screen (e.g. DP-2),
		// otherwise the screen with the most pixels (your 2K monitor).
		screen: Quickshell.screens.find(s => s.name === Quickshell.env("happybar_main_screen"))
			?? Quickshell.screens.reduce((best, s) => (!best || s.width * s.height > best.width * best.height) ? s : best, null)

		anchors {
			top: true
			left: true
			right: true
		}

		margins {
			top: 16
			right: sideMargin
			left: sideMargin
			bottom: 0
		}

		color: "transparent"
		implicitHeight: 48

		ControlPanel {
			id: control_panel
			bar: my_bar
		}

		Rectangle {
			id: bar_container
			anchors.fill: parent
			radius: 30
			color: Theme.bar
			height: 48

			// square the corner whenever the panel is attached, so the two join with no notch
			bottomRightRadius: my_bar.cpShown ? 0 : 30


			Row {
				id: leftContentRow

				spacing: 8
				anchors.left: parent.left
				anchors.leftMargin: 8
				anchors.verticalCenter: parent.verticalCenter
				ClockWidget {}
				SystrayWidget {}
			}

			Row {
				id: rightContentRow
				anchors.right: parent.right
				anchors.rightMargin: 8
				spacing: 8
				anchors.verticalCenter: parent.verticalCenter
				ControlPanelWidget {
					container: bar_container
					bar: my_bar
				}
			}
		}
	}

	// Transparent click-catcher below the bar: clicking anywhere on the screen
	// outside the control panel closes it. The bar itself stays clickable.
	PanelWindow {
		id: click_catcher
		screen: my_bar.screen
		visible: my_bar.cpOpen
		color: "transparent"
		exclusionMode: ExclusionMode.Ignore

		anchors { top: true; bottom: true; left: true; right: true }
		margins { top: my_bar.margins.top + my_bar.implicitHeight }

		// let clicks through on the panel itself
		mask: Region {
			x: 0; y: 0; width: click_catcher.width; height: click_catcher.height
			Region {
				intersection: Intersection.Subtract
				x: click_catcher.width - my_bar.sideMargin - control_panel.width
				y: 0
				width: control_panel.width
				height: control_panel.height
			}
		}

		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
			onPressed: my_bar.cpOpen = false
		}
	}
}
