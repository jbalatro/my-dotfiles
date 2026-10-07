import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Services.SystemTray

Rectangle {
	id: systray_widget
	property int fontSize: 16
	property int paddingH: 32
	property int paddingV: 8

	color: Theme.pill
	radius: 30
	implicitHeight: systray_row.height + paddingV
	implicitWidth: systray_row.width + paddingH

	// click anywhere on the widget (below the tray icons) to collapse/expand it
	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: systray_items.active = !systray_items.active
	}

	Row {
		id: systray_row
		// gap scales with the reveal so nothing jumps while animating
		spacing: 12 * systray_items.reveal
		anchors.verticalCenter: parent.verticalCenter
		anchors.horizontalCenter: parent.horizontalCenter
		Text {
			id: icon_systray
			color: Theme.ink
			text: ""
			font.pixelSize: systray_widget.fontSize + 4
			font.family: "JetBrainsMono Nerd Font"
			anchors.verticalCenter: parent.verticalCenter
		}
	
		Row {
			id: systray_items
			anchors.verticalCenter: parent.verticalCenter
			spacing: 16
			property bool active: true
			// 0 = collapsed, 1 = expanded; width, gap and opacity all follow it in sync
			property real reveal: active ? 0 : 1
			Behavior on reveal {
				NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
			}
			width: implicitWidth * reveal
			opacity: reveal
			antialiasing: true
			clip: true
			Repeater {
				property bool active: false
				model: SystemTray.items
				MouseArea {
					width: 16
					height: 16
					anchors.verticalCenter: parent.verticalCenter
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					IconImage {
						id: tray_icon_image
						visible: true
						source: modelData.icon
						anchors.centerIn: parent
						width: 18
						height: 18
					}

					onDoubleClicked: {
						modelData.activate()
					}

					onClicked: (mouse) => {
						switch(mouse.button) {
							case Qt.RightButton:
								var pos = mapToItem(null, mouse.x, mouse.y);
								if (modelData.hasMenu) {
									modelData.display(my_bar, pos.x, pos.y);
								}
								break;
						}
					}

					QsMenuOpener {
						id: menuOpen
						menu: modelData.menu
					}
				}
			}
		}
	}
}