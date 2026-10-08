import QtQuick
import Quickshell
import Quickshell.Io

// Mango tags as numbered dots. Only tags holding windows are shown, plus the
// active one so you always know where you are. Click a dot to switch to it.
Rectangle {
	id: workspaces_widget
	// monitor whose tags are shown (the bar's screen)
	property string monitor: ""
	property int dotSize: 24
	property var tags: []

	color: Theme.pill
	radius: 30
	visible: tags.length > 0

	implicitHeight: dotSize + 8
	implicitWidth: dot_row.width + 8

	// mmsg prints one JSON line with every tag on every change
	Process {
		id: watcher
		running: true
		command: ["mmsg", "watch", "all-tags"]
		stdout: SplitParser {
			onRead: (line) => {
				let data
				try { data = JSON.parse(line) } catch (e) { return }
				const mons = data.all_tags ?? []
				const mon = mons.find(m => m.monitor === workspaces_widget.monitor) ?? mons[0]
				workspaces_widget.tags = mon ? mon.tags.filter(t => t.client_count > 0 || t.is_active) : []
			}
		}
		// restart if mango drops the stream (e.g. after a config reload)
		onExited: restart.start()
	}

	Timer {
		id: restart
		interval: 1000
		onTriggered: watcher.running = true
	}

	Process { id: dispatcher }

	Row {
		id: dot_row
		spacing: 4
		anchors.centerIn: parent

		Repeater {
			model: workspaces_widget.tags

			Rectangle {
				id: dot
				required property var modelData
				readonly property bool active: modelData.is_active

				width: workspaces_widget.dotSize
				height: workspaces_widget.dotSize
				radius: width / 2
				// active tag is filled, the others blend into the pill
				color: active ? Theme.ink : (mouse.containsMouse ? Theme.tileHover : "transparent")
				Behavior on color { ColorAnimation { duration: 150 } }

				Text {
					anchors.centerIn: parent
					text: dot.modelData.index
					color: dot.active ? Theme.pill : Theme.ink
					font.pixelSize: 13
					font.bold: true
					font.family: "JetBrainsMono Nerd Font"
					Behavior on color { ColorAnimation { duration: 150 } }
				}

				MouseArea {
					id: mouse
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						dispatcher.command = ["mmsg", "dispatch", "view," + dot.modelData.index + ",0"]
						dispatcher.running = true
					}
				}
			}
		}
	}
}
