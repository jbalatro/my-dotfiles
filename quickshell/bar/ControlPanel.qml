import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Quick-settings panel that drops out of the bar, on the right side.
PopupWindow {
	id: bar_cp
	required property var bar

	readonly property color bgColor: Theme.bar
	readonly property color tileColor: Theme.pill
	readonly property color tileActive: Theme.tileActive
	readonly property color inkColor: Theme.ink
	readonly property string iconFont: "JetBrainsMono Nerd Font"

	readonly property int panelWidth: Math.round(Math.min(420, bar.width * 0.3))
	readonly property int filletSize: 28
	readonly property int gap: 12
	readonly property int tile: Math.round((panelWidth * 0.6 - gap * 5) / 4)
	// laptop: toggles, volume, power profile, session; desktop has no profile row
	readonly property int rows: isLaptop ? 4 : 3
	readonly property int panelHeight: tile * rows + gap * (rows + 1)

	readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
	readonly property PwNode sink: Pipewire.defaultAudioSink
	readonly property PwNode source: Pipewire.defaultAudioSource

	// set per machine via the happybar_pc_type environment variable (DESKTOP or LAPTOP)
	readonly property bool isLaptop: Quickshell.env("happybar_pc_type") === "LAPTOP"

	property bool wifiOn: false
	property string powerProfile: "balanced"

	// stays mapped while the retract animation is still running
	readonly property bool shown: bar.cpOpen || reveal.height > 1
	visible: shown

	Binding { target: bar; property: "cpShown"; value: bar_cp.shown }
	implicitWidth: panelWidth + filletSize
	implicitHeight: panelHeight
	color: "transparent"
	anchor.window: bar
	anchor.rect.x: bar.width - width
	anchor.rect.y: bar.height - 2

	PwObjectTracker { objects: [bar_cp.sink, bar_cp.source] }

	// ---- system state -------------------------------------------------
	Process {
		id: wifiRead
		command: ["nmcli", "radio", "wifi"]
		stdout: StdioCollector { onStreamFinished: bar_cp.wifiOn = text.trim() === "enabled" }
	}
	Process { id: wifiSet; onExited: wifiRead.running = true }
	Process {
		id: profileRead
		command: ["powerprofilesctl", "get"]
		stdout: StdioCollector { onStreamFinished: bar_cp.powerProfile = text.trim() }
	}
	Process { id: profileSet; onExited: profileRead.running = true }
	Process { id: sessionCmd }

	function refresh() {
		wifiRead.running = true;
		profileRead.running = true;
	}
	function setWifi(on) { wifiSet.command = ["nmcli", "radio", "wifi", on ? "on" : "off"]; wifiSet.running = true }
	function setProfile(p) { profileSet.command = ["powerprofilesctl", "set", p]; profileSet.running = true }
	function run(cmd) { sessionCmd.command = cmd; sessionCmd.running = true; bar.cpOpen = false }

	Connections {
		target: bar
		function onCpOpenChanged() { if (bar.cpOpen) bar_cp.refresh() }
	}

	// ---- reusable pieces ---------------------------------------------
	component RoundToggle: Rectangle {
		id: rt
		property string glyph
		property bool active: false
		signal clicked()
		width: bar_cp.tile; height: bar_cp.tile; radius: width / 2
		color: active ? bar_cp.tileActive : bar_cp.tileColor
		opacity: active ? 1.0 : 0.65
		Behavior on opacity { NumberAnimation { duration: 150 } }
		Text {
			anchors.centerIn: parent
			text: rt.glyph
			color: bar_cp.inkColor
			font.family: bar_cp.iconFont
			font.pixelSize: bar_cp.tile * 0.42
		}
		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: rt.clicked()
		}
	}

	component Pill: Rectangle {
		width: leftCol.width; height: bar_cp.tile; radius: height / 2
		color: bar_cp.tileColor
	}

	component SmallButton: Rectangle {
		id: sb
		property string glyph
		property bool active: false
		signal clicked()
		height: bar_cp.tile - 14; width: height; radius: width / 2
		color: active ? bar_cp.inkColor : (ma.containsMouse ? Theme.tileHover : "transparent")
		Text {
			anchors.centerIn: parent
			text: sb.glyph
			color: sb.active ? bar_cp.tileColor : bar_cp.inkColor
			font.family: bar_cp.iconFont
			font.pixelSize: sb.height * 0.45
		}
		MouseArea {
			id: ma
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: sb.clicked()
		}
	}

	// ---- panel body ---------------------------------------------------
	// Concave corner that flows the panel's left edge into the bar
	Item {
		x: 0; y: 0
		width: bar_cp.filletSize
		height: Math.max(0, Math.min(bar_cp.filletSize, reveal.height))
		clip: true
		Shape {
			width: bar_cp.filletSize; height: bar_cp.filletSize
			layer.enabled: true
			layer.samples: 4
			ShapePath {
				fillColor: bar_cp.bgColor
				strokeColor: "transparent"
				startX: bar_cp.filletSize; startY: 0
				PathLine { x: bar_cp.filletSize; y: bar_cp.filletSize }
				PathArc {
					x: 0; y: 0
					radiusX: bar_cp.filletSize; radiusY: bar_cp.filletSize
					direction: PathArc.Counterclockwise
				}
				PathLine { x: bar_cp.filletSize; y: 0 }
			}
		}
	}

	// The body keeps its full size and rounded corners; this box just wipes it
	// open/closed from the top, so the panel looks like it slides out of the bar.
	Item {
		id: reveal
		x: bar_cp.filletSize
		y: 0
		width: bar_cp.panelWidth
		height: bar.cpOpen ? bar_cp.panelHeight : 0
		clip: true

		Behavior on height {
			NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
		}

	Rectangle {
		id: body
		x: 0
		y: 0
		width: bar_cp.panelWidth
		height: bar_cp.panelHeight
		color: bar_cp.bgColor
		topLeftRadius: 0
		topRightRadius: 0
		bottomLeftRadius: 30
		bottomRightRadius: 30

		// left column: toggles, then three pills
		Column {
			id: leftCol
			x: bar_cp.gap; y: bar_cp.gap
			width: Math.round((bar_cp.panelWidth - bar_cp.gap * 3) * 0.5)
			spacing: bar_cp.gap

			Row {
				width: parent.width
				spacing: (parent.width - bar_cp.tile * 3) / 2

				RoundToggle {
					glyph: ""
					active: bar_cp.wifiOn
					onClicked: bar_cp.setWifi(!bar_cp.wifiOn)
				}
				RoundToggle {
					glyph: ""
					active: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
					onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
				}
				RoundToggle {
					glyph: bar_cp.source && bar_cp.source.audio && bar_cp.source.audio.muted ? "" : ""
					active: bar_cp.source && bar_cp.source.audio ? !bar_cp.source.audio.muted : false
					onClicked: if (bar_cp.source && bar_cp.source.audio) bar_cp.source.audio.muted = !bar_cp.source.audio.muted
				}
			}

			// volume
			Pill {
				Text {
					id: volIcon
					x: 18
					anchors.verticalCenter: parent.verticalCenter
					text: bar_cp.sink && bar_cp.sink.audio && bar_cp.sink.audio.muted ? "" : ""
					color: bar_cp.inkColor
					font.family: bar_cp.iconFont
					font.pixelSize: bar_cp.tile * 0.38
					MouseArea {
						anchors.fill: parent
						anchors.margins: -8
						cursorShape: Qt.PointingHandCursor
						onClicked: if (bar_cp.sink && bar_cp.sink.audio) bar_cp.sink.audio.muted = !bar_cp.sink.audio.muted
					}
				}
				Slider {
					id: volSlider
					anchors.left: volIcon.right
					anchors.leftMargin: 12
					anchors.right: parent.right
					anchors.rightMargin: 18
					anchors.verticalCenter: parent.verticalCenter
					// explicit height: without it the slider is 0px tall and has nothing to grab
					height: 28
					from: 0; to: 1
					// PipeWire echoes back older values after fast writes, which made the handle
					// chase them. While dragging (and briefly after) the slider keeps its own value.
					Binding {
						target: volSlider
						property: "value"
						value: bar_cp.sink && bar_cp.sink.audio ? bar_cp.sink.audio.volume : 0
						when: !volSlider.pressed && !settle.running
						restoreMode: Binding.RestoreNone
					}
					Timer { id: settle; interval: 350 }
					onPressedChanged: if (!pressed) settle.restart()
					onMoved: {
						if (!bar_cp.sink || !bar_cp.sink.audio) return
						if (bar_cp.sink.audio.muted) bar_cp.sink.audio.muted = false
						bar_cp.sink.audio.volume = value
					}
					background: Rectangle {
						y: volSlider.availableHeight / 2 - height / 2
						width: volSlider.availableWidth; height: 8; radius: 4
						color: Theme.track
						Rectangle {
							width: volSlider.visualPosition * parent.width
							height: parent.height; radius: 4
							color: bar_cp.inkColor
						}
					}
					handle: Rectangle {
						x: volSlider.visualPosition * (volSlider.availableWidth - width)
						y: volSlider.availableHeight / 2 - height / 2
						width: 16; height: 16; radius: 8
						color: bar_cp.inkColor
					}
				}
			}

			// power profile (laptop)
			Pill {
				visible: bar_cp.isLaptop
				Row {
					anchors.centerIn: parent
					spacing: 14
					SmallButton { glyph: ""; active: bar_cp.powerProfile === "power-saver"; onClicked: bar_cp.setProfile("power-saver") }
					SmallButton { glyph: ""; active: bar_cp.powerProfile === "balanced"; onClicked: bar_cp.setProfile("balanced") }
					SmallButton { glyph: ""; active: bar_cp.powerProfile === "performance"; onClicked: bar_cp.setProfile("performance") }
				}
			}

			// session: restart and power off as two separate pills
			Row {
				spacing: bar_cp.gap
				Repeater {
					model: [
						{ glyph: "\uf021", cmd: ["systemctl", "reboot"] },
						{ glyph: "\uf011", cmd: ["systemctl", "poweroff"] }
					]
					Rectangle {
						required property var modelData
						width: (leftCol.width - bar_cp.gap) / 2
						height: bar_cp.tile
						radius: height / 2
						color: sessionMa.containsMouse ? Theme.tileHover : bar_cp.tileColor
						Behavior on color { ColorAnimation { duration: 120 } }
						Text {
							anchors.centerIn: parent
							text: parent.modelData.glyph
							color: bar_cp.inkColor
							font.family: bar_cp.iconFont
							font.pixelSize: bar_cp.tile * 0.38
						}
						MouseArea {
							id: sessionMa
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: bar_cp.run(parent.modelData.cmd)
						}
					}
				}
			}

		}

		// right: media tile
		Rectangle {
			id: media
			x: leftCol.x + leftCol.width + bar_cp.gap
			y: bar_cp.gap
			width: bar_cp.panelWidth - x - bar_cp.gap
			height: bar_cp.panelHeight - bar_cp.gap * 2
			radius: 30
			color: bar_cp.tileColor
			clip: true

			// rounded-corner mask so the art follows the tile's shape
			Item {
				id: artMask
				anchors.fill: parent
				visible: false
				layer.enabled: true
				Rectangle { anchors.fill: parent; radius: media.radius }
			}

			// art and fade live in one masked layer so both follow the tile's rounded corners
			Item {
				anchors.fill: parent
				visible: art.status === Image.Ready
				layer.enabled: true
				layer.effect: MultiEffect {
					maskEnabled: true
					maskSource: artMask
				}

				Image {
					id: art
					anchors.fill: parent
					fillMode: Image.PreserveAspectCrop
					source: bar_cp.player && bar_cp.player.trackArtUrl ? bar_cp.player.trackArtUrl : ""
					opacity: 0.55
				}

				// fade the art toward the bottom so the text stays readable
				Rectangle {
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.bottom: parent.bottom
					height: parent.height * 0.6
					gradient: Gradient {
						GradientStop { position: 0.0; color: "transparent" }
						GradientStop { position: 1.0; color: bar_cp.tileColor }
					}
				}
			}

			Text {
				anchors.centerIn: parent
				visible: !bar_cp.player
				text: ""
				color: Theme.track
				font.family: bar_cp.iconFont
				font.pixelSize: 56
			}

			Column {
				visible: bar_cp.player !== null
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				anchors.margins: 18
				spacing: 4

				Text {
					width: parent.width
					text: bar_cp.player ? (bar_cp.player.trackTitle || "Unknown") : ""
					color: bar_cp.inkColor
					font.pixelSize: 15
					font.bold: true
					elide: Text.ElideRight
				}
				Text {
					width: parent.width
					text: bar_cp.player ? (bar_cp.player.trackArtist || "") : ""
					color: Theme.subInk
					font.pixelSize: 12
					elide: Text.ElideRight
				}
				Item { width: 1; height: 6 }
				Row {
					anchors.horizontalCenter: parent.horizontalCenter
					spacing: 18
					height: 40
					SmallButton { glyph: ""; height: 40; onClicked: if (bar_cp.player) bar_cp.player.previous() }
					SmallButton {
						glyph: bar_cp.player && bar_cp.player.isPlaying ? "" : ""
						height: 40
						active: true
						onClicked: if (bar_cp.player) bar_cp.player.togglePlaying()
					}
					SmallButton { glyph: ""; height: 40; onClicked: if (bar_cp.player) bar_cp.player.next() }
				}
			}
		}
	}
	}
}
