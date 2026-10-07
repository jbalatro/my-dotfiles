//@ pragma UseQApplication
// Runner.qml
import QtQuick
import QtQuick.Controls
import Quickshell
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Wayland

Scope {
    // 1. ARRAY TO HOLD FILTERED APPS
    property var filteredApps: []

    // 2. FAST JAVASCRIPT FILTER FUNCTION
	function updateSearch() {
		let query = searchApplication.text.toLowerCase().trim();

		// 1. Convert the UntypedObjectModel into a standard JavaScript array
        let allApps = DesktopEntries.applications.values.filter(a => !a.noDisplay);

		// 2. Now we can safely use the .filter() function!
		if (query === "") {
			filteredApps = allApps;
		} else {
			filteredApps = allApps.filter(app => {
				return app.name.toLowerCase().includes(query) || 
					(app.comment && app.comment.toLowerCase().includes(query));
			});
		}
		
		// Reset our list view selection to the top match
		if (appList) {
			appList.currentIndex = 0;
		}
	}

    // Concave corner that flows the panel's top edge into the bar's bottom edge
    component Fillet: Item {
        id: fillet
        property bool mirrored: false
        property color color: Theme.bar
        readonly property int r: 28

        width: r
        // reveal progressively while the panel grows or retracts
        // only where the panel's side is still straight (above its rounded bottom corners)
        height: Math.max(0, Math.min(r, bar_container.height - bar_container.bottomLeftRadius))
        clip: true

        Shape {
            width: fillet.r; height: fillet.r
            layer.enabled: true
            layer.samples: 4
            transform: Scale { origin.x: fillet.r / 2; xScale: fillet.mirrored ? -1 : 1 }

            ShapePath {
                fillColor: fillet.color
                strokeColor: "transparent"
                startX: fillet.r; startY: 0
                PathLine { x: fillet.r; y: fillet.r }
                PathArc {
                    x: 0; y: 0
                    radiusX: fillet.r; radiusY: fillet.r
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: fillet.r; y: 0 }
            }
        }
    }

    // Retract the panel, then exit once the animation has finished
    function closeRunner() {
        if (!bar_container.open) return;
        bar_container.open = false;
        quitTimer.start();
    }

    Timer {
        id: quitTimer
        interval: 450
        onTriggered: Qt.quit()
    }

    // Populate apps array on startup, and again once the entries finish loading
    Component.onCompleted: updateSearch()
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { updateSearch() }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: modelData !== app_runner.screen

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            MouseArea {
                anchors.fill: parent
                onClicked: closeRunner()
            }
        }
    }

    PanelWindow {
        id: app_runner

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        focusable: true
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        Item {
            id: windowKeyHandler
            anchors.fill: parent
            focus: true 

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    closeRunner()
                    event.accepted = true;
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: closeRunner()
            }

            // Bar sits at top margin 16 with height 48; attach just under it
            Rectangle {
                id: bar_container
                property bool open: false

                anchors.horizontalCenter: parent.horizontalCenter
                y: 16 + 48 - 2
                // scale with the screen so it also fits on a laptop
                readonly property real fullHeight: Math.min(512, parent.height * 0.6)
                width: Math.min(1024, parent.width * 0.6)
                height: open ? fullHeight : 0
                clip: true
                color: Theme.bar
                topLeftRadius: 0
                topRightRadius: 0
                bottomLeftRadius: 32
                bottomRightRadius: 32

                Behavior on height {
                    NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
                }

                // let the window and list settle before animating, so the first frames aren't dropped
                Timer {
                    running: true
                    interval: 60
                    onTriggered: bar_container.open = true
                }

                // swallow clicks so they don't close the runner
                MouseArea { anchors.fill: parent }

                TextField {
                    id: searchApplication
                    width: parent.width - 40
                    height: 40
                    font.pixelSize: 18
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 20
                    leftPadding: 15
                    
                    color: Theme.ink
                    placeholderText: "Search apps..."
                    placeholderTextColor: Theme.subInk

                    background: Rectangle {
                        color: Theme.pill
                        radius: 32
                    }

                    // Update our filtered data model dynamically as you type
                    onTextChanged: updateSearch()

                    // Keyboard arrow mapping navigation
                    Keys.onDownPressed: appList.incrementCurrentIndex()
                    Keys.onUpPressed: appList.decrementCurrentIndex()

                    // Run the selected application on pressing Enter
                    onAccepted: {
                        let currentApp = filteredApps[appList.currentIndex];
                        if (currentApp) {
                            console.log("Launching: " + currentApp.name);
                            currentApp.execute();
                            closeRunner();
                        }
                    }
                    
                    Component.onCompleted: forceActiveFocus()
                }

                ListView {
                    id: appList
                    width: parent.width - 40
                    anchors.top: searchApplication.bottom
                    // fixed height (not bound to the animated one) so the list isn't re-laid-out every frame
                    height: bar_container.fullHeight - searchApplication.height - 20 - 15 - 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 15
                    clip: true 

                    // keep the arrow-key selection visible while scrolling through the list
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    // Using our dynamic array instead of the raw system list
                    model: filteredApps

                    delegate: Item {
                        id: appDelegate
                        width: appList.width
                        height: 45 // Fixed height setup (No duplicates!)
                        
                        function launchApp() {
                            console.log("Launching: " + modelData.name);
                            modelData.execute(); 
                            closeRunner(); 
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 32
                            // one highlight shared by arrow-key selection and mouse hover
                            color: appDelegate.ListView.isCurrentItem ? Theme.barHover : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 15
                                spacing: 15

                                Text {
                                    text: modelData.name
                                    color: Theme.barInk
                                    font.pixelSize: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData.comment ? modelData.comment : ""
                                    color: "#888888"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    width: parent.width - 200
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                // only real mouse movement moves the selection, so arrow scrolling isn't hijacked
                                onPositionChanged: appList.currentIndex = index
                                onClicked: appDelegate.launchApp()
                            }
                        }
                    }
                }
            }
            Fillet {
                x: bar_container.x - width
                y: bar_container.y
            }

            Fillet {
                mirrored: true
                x: bar_container.x + bar_container.width
                y: bar_container.y
            }
        }
    }
}