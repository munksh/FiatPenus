// What is left on the list last looked at, the one number worth a glance in a
// shop. No actions: ticking off belongs on the list itself.
import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

CoverBackground {
    id: cover

    // ---- state ----
    readonly property bool hasList: api.coverTitle !== "" && api.coverOpen >= 0

    // ---- paper ----
    FiatBackground { }

    // ---- wordmark ----
    Label {
        anchors.top: parent.top
        anchors.topMargin: FiatPenusTheme.coverWordmarkTop
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        text: "fiat penus"
        color: FiatPenusTheme.secondaryText
        font.pixelSize: Theme.fontSizeTiny
        font.family: FiatPenusTheme.serif
        font.italic: true
    }

    // ---- figure ----
    Column {
        y: cover.height * FiatPenusTheme.coverFigureFraction
        x: FiatPenusTheme.coverSideMargin
        width: parent.width - 2 * FiatPenusTheme.coverSideMargin
        spacing: Theme.paddingSmall
        visible: cover.hasList

        Item {
            width: parent.width
            height: figure.height
            Label {
                id: figure
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: api.coverOpen
                opacity: api.coverOpen > 0 ? 1.0 : 0.0
                color: FiatPenusTheme.accent
                font.pixelSize: FiatPenusTheme.coverFigureSize
                font.family: FiatPenusTheme.serif
            }
            // Everything ticked off: the list's own mark, drawn, not a glyph.
            Mark {
                anchors.centerIn: parent
                width: figure.height * 0.6
                visible: api.coverOpen === 0
                checked: true
            }
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            //: Cover, under the number of items left: "left · Groceries"
            text: api.coverOpen > 0 ? qsTr("left · %1").arg(api.coverTitle) : api.coverTitle
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: FiatPenusTheme.secondaryText
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }
    Label {
        y: cover.height * FiatPenusTheme.coverFigureFraction
        x: FiatPenusTheme.coverSideMargin
        width: parent.width - 2 * FiatPenusTheme.coverSideMargin
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: !cover.hasList
        text: qsTr("no list open")
        color: FiatPenusTheme.secondaryText
        font.pixelSize: Theme.fontSizeSmall
        font.family: FiatPenusTheme.serif
        font.italic: true
    }
}
