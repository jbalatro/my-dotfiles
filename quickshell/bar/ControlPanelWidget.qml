import QtQuick
import Quickshell

Rectangle {
	id: cp_widget
	property int fontSize: 16
	property int paddingH: 32
	property int paddingV: 8

	required property var container
	required property var bar

	color: Theme.pill
	radius: 30

	implicitHeight: cp_widget_row.height + paddingV
	implicitWidth: cp_widget_row.width + paddingH
	Row {
		id: cp_widget_row
		spacing: 12
		anchors.verticalCenter: parent.verticalCenter
		anchors.horizontalCenter: parent.horizontalCenter
		Text {
			id: icon
			color: Theme.ink
			text: "⏻"
			font.pixelSize: cp_widget.fontSize + 4
			font.family: "JetBrainsMono Nerd Font"
			anchors.verticalCenter: parent.verticalCenter
		}
	}

	MouseArea {
		anchors.fill: parent
		onClicked: {
			bar.cpOpen = !bar.cpOpen
		}
	}
}