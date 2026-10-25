import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// The wordmark on the status row, in the free corner beside the cutout, and
// under it the three sides of the household in reading order: the lists, the
// notes on the wall and the photo board. Three words do not fit beside the
// wordmark the way Agenda's two do, and a side that wraps to a line of its
// own reads as something else.
Item {
    id: root

    property string mode: "lists"
    signal chosen(string mode)

    width: parent ? parent.width : 0
    height: sides.y + sides.height + Theme.paddingSmall

    Text {
        id: word
        anchors.left: parent.left
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.top: parent.top
        anchors.topMargin: Math.max(0, FiatPenusTheme.statusRowCenter - height / 2)
        text: "fiat penus"
        color: FiatPenusTheme.primaryText
        font.pixelSize: Theme.fontSizeLarge
        font.family: FiatPenusTheme.serif
        font.italic: true
    }

    // A Flow of fixed width, not a Row: a Pill sizes itself from its parent's
    // width, and a Row sizes itself from its children.
    Flow {
        id: sides
        x: Theme.horizontalPageMargin - Theme.paddingMedium
        y: word.y + word.height + Theme.paddingSmall
        width: root.width - x - Theme.horizontalPageMargin
        spacing: Theme.paddingSmall
        Pill {
            text: qsTr("Lists")
            pixelSize: FiatPenusTheme.navFontSize
            selected: root.mode === "lists"
            onClicked: root.chosen("lists")
        }
        Pill {
            text: qsTr("Notes")
            pixelSize: FiatPenusTheme.navFontSize
            selected: root.mode === "notes"
            onClicked: root.chosen("notes")
        }
        Pill {
            text: qsTr("Photos")
            pixelSize: FiatPenusTheme.navFontSize
            selected: root.mode === "photos"
            onClicked: root.chosen("photos")
        }
    }
}
