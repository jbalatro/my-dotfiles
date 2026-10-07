import QtQuick
import Quickshell

Rectangle {
	id: clock_widget
	property int fontSize: 16
	property int paddingH: 32
	property int paddingV: 8
	property bool showTime: true
	property bool showDate: false

	color: Theme.pill
	radius: 30

	implicitHeight: clock_row.height + paddingV
	implicitWidth: clock_row.width + paddingH

	Row {
		id: clock_row
		spacing: 0
		anchors.verticalCenter: parent.verticalCenter
		anchors.horizontalCenter: parent.horizontalCenter
		Text {
			id: icon
			color: Theme.ink
			text: ""
			font.pixelSize: clock_widget.fontSize + 4
			font.family: "JetBrainsMono Nerd Font"
			anchors.verticalCenter: parent.verticalCenter
		}
		// each part expands/collapses on its own 0..1 value, so the icon never moves
		Item {
			id: date_part
			property real reveal: clock_widget.showDate ? 1 : 0
			Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
			width: (date_text.implicitWidth + 12) * reveal
			height: date_text.implicitHeight
			opacity: reveal
			clip: true
			anchors.verticalCenter: parent.verticalCenter
			Text {
				id: date_text
				x: 12
				text: Time.date
				color: Theme.ink
				font.pixelSize: clock_widget.fontSize
				font.family: "JetBrainsMono Nerd Font"
			}
		}
		Item {
			id: time_part
			property real reveal: clock_widget.showTime ? 1 : 0
			Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
			width: (time_text.implicitWidth + 12) * reveal
			height: time_text.implicitHeight
			opacity: reveal
			clip: true
			anchors.verticalCenter: parent.verticalCenter
			Text {
				id: time_text
				x: 12
				text: Time.time
				color: Theme.ink
				font.pixelSize: clock_widget.fontSize
				font.family: "JetBrainsMono Nerd Font"
			}
		}
	}

	// left click: collapse everything / show the time, right click: show/hide the date
	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor
		onClicked: (mouse) => {
			if (mouse.button === Qt.RightButton)
				clock_widget.showDate = !clock_widget.showDate
			else if (clock_widget.showTime || clock_widget.showDate) {
				// anything visible: collapse everything
				clock_widget.showTime = false
				clock_widget.showDate = false
			} else
				clock_widget.showTime = true
		}
	}
}
