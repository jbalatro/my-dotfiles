import QtQuick
import Quickshell
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Services.Pipewire

Rectangle {
	id: volume_widget
	property int fontSize: 16
	property int paddingH: 32
	property int paddingV: 8
	required property PwNode node;
	PwObjectTracker { objects: [ node ] }

	color: "#d3cfcf"
	radius: 30
	implicitHeight: volume_row.height + paddingV
	implicitWidth: volume_row.width + paddingH
	Row {

		id: volume_row
		spacing: 12
		anchors.verticalCenter: parent.verticalCenter
		anchors.horizontalCenter: parent.horizontalCenter
		Text {
			id: icon_volume
			text: ""
			font.pixelSize: volume_widget.fontSize + 4
			font.family: "JetBrainsMono Nerd Font"
			anchors.verticalCenter: parent.verticalCenter
			MouseArea {
				anchors.fill: parent
				onClicked: { 
					volume_slider.active = !volume_slider.active
				}
			}
		}
		Slider {
			id: volume_slider
			property bool active: false
			anchors.verticalCenter: parent.verticalCenter
			implicitWidth: active ? 120 : 0
			opacity: 1
			antialiasing: true
			clip: true
			from: 0.0
			to: 1.0

			value: node.audio.volume 
			onValueChanged: node.audio.volume = value

			Behavior on implicitWidth {
				NumberAnimation { duration: 300; easing.type: volume_slider.active ?  Easing.InQuint : Easing.OutCubic}
			}
			
			background: Rectangle {
				x: volume_slider.leftPadding
				y: volume_slider.topPadding + volume_slider.availableHeight / 2 - height / 2
				implicitWidth: 200
				implicitHeight: 10
				width: volume_slider.availableWidth
				height: implicitHeight
				radius: 32
				color: '#484b4e'

				Rectangle {
					width: volume_slider.visualPosition * parent.width
					height: parent.height
					color: '#202529'
					radius: 32
				}
			}

			handle: Rectangle {
				x: volume_slider.leftPadding + volume_slider.visualPosition * (volume_slider.availableWidth - width)
				y: volume_slider.topPadding + volume_slider.availableHeight / 2 - height / 2
				implicitWidth: 16
				implicitHeight: 16
				radius: 32
				color: volume_slider.pressed ? '#202529' : '#202529'
				border.color: "transparent"
			}
		}
	}
}