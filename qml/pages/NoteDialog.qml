import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"
import "../js/util.js" as U

// A note's title, its text in Markdown, and its colour on the wall.
Dialog {
    id: dialog

    property int noteId: 0
    property string title: ""
    property string content: ""
    property string colour: ""

    canAccept: titleField.text.trim() !== ""

    function fields() {
        return { "title": titleField.text.trim(), "content": contentField.text, "color": dialog.colour }
    }

    function paint() { FiatPenusTheme.applyPalette(dialog) }
    Component.onCompleted: paint()

    FiatBackground { }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge * 2

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingSmall

            DialogHead {
                owner: dialog
                title: dialog.noteId > 0 ? qsTr("note") : qsTr("a new note")
            }
            TextField {
                id: titleField
                width: parent.width
                text: dialog.title
                label: qsTr("Title")
                placeholderText: qsTr("Title")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: contentField.focus = true
            }
            TextArea {
                id: contentField
                width: parent.width
                text: dialog.content
                label: qsTr("Markdown works: **bold**, - lists, - [ ] ticks")
                placeholderText: qsTr("What the note says")
            }

            Item { width: 1; height: Theme.paddingMedium }
            SectionLabel { x: Theme.horizontalPageMargin; text: qsTr("Colour") }
            ColourChoice {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                colours: U.listColours
                current: dialog.colour
                onChosen: dialog.colour = value
            }
        }

        VerticalScrollDecorator { }
    }
}
