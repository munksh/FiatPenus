import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"
import "../js/util.js" as U

// Where a photo should hang: on the board itself, or in one of its folders.
Page {
    id: page

    property var folders: []
    property int selectedId: 0

    signal picked(int id)

    function paint() { FiatPenusTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections { target: FiatPenusTheme; onAmbientChanged: page.paint() }

    FiatBackground { }

    SilicaListView {
        id: view
        anchors.fill: parent
        model: [{ "id": 0, "name": qsTr("the board, no folder") }].concat(page.folders)
        header: PageHead { title: qsTr("move to") }

        delegate: BackgroundItem {
            id: row
            readonly property bool current: modelData.id === page.selectedId
            height: Theme.itemSizeSmall
            highlightedColor: FiatPenusTheme.highlightWash
            onClicked: {
                page.picked(modelData.id)
                pageStack.pop()
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: U.str(modelData.name)
                truncationMode: TruncationMode.Fade
                color: row.current ? FiatPenusTheme.accent : FiatPenusTheme.primaryText
                font.bold: row.current
                font.italic: modelData.id === 0
                font.family: modelData.id === 0 ? FiatPenusTheme.serif : Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
            }
        }

        VerticalScrollDecorator { }
    }
}
