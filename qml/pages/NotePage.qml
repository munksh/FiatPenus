import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"
import "../js/util.js" as U
import "../js/markdown.js" as Md
import "../js/shelf.js" as Shelf

// One note, read in full, with its Markdown set.
Page {
    id: page

    property var house
    property var note

    signal changed()
    signal removed(int noteId)

    readonly property string path: "/houses/" + (house ? house.id : 0) + "/notes/" + (note ? note.id : 0)
    readonly property bool editable: note && note.canEdit !== false

    function paint() { FiatPenusTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections { target: FiatPenusTheme; onAmbientChanged: page.paint() }

    function edit() {
        var d = pageStack.push(Qt.resolvedUrl("NoteDialog.qml"), {
            "noteId": note.id, "title": U.str(note.title), "content": U.str(note.content), "colour": U.str(note.color) })
        d.accepted.connect(function () {
            Shelf.send("PATCH", page.path, d.fields(), function (ok, data) {
                if (ok && data && data.id) {
                    page.note = data
                    page.changed()
                }
            })
        })
    }

    function pin() {
        Shelf.send("PATCH", path, { "isPinned": !note.isPinned }, function (ok, data) {
            if (ok && data && data.id) {
                page.note = data
                page.changed()
            }
        })
    }

    RemorsePopup { id: remorse }

    FiatBackground { }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge * 2

        PullDownMenu {
            highlightColor: FiatPenusTheme.chromeAccent
            visible: page.editable || U.can(page.house, "canDeleteNotes")
            MenuItem {
                visible: U.can(page.house, "canDeleteNotes")
                text: qsTr("Delete")
                color: FiatPenusTheme.primaryText
                onClicked: remorse.execute(qsTr("Deleting"), function () {
                    page.removed(page.note.id)
                    pageStack.pop()
                })
            }
            MenuItem {
                visible: page.editable
                text: page.note && page.note.isPinned ? qsTr("Unpin") : qsTr("Pin")
                color: FiatPenusTheme.primaryText
                onClicked: page.pin()
            }
            MenuItem {
                visible: page.editable
                text: qsTr("Edit")
                color: FiatPenusTheme.primaryText
                onClicked: page.edit()
            }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHead {
                title: page.note ? U.str(page.note.title) : ""
                subtitle: page.note && page.note.isPinned ? qsTr("pinned") : ""
            }
            ErrorLine { visible: !(page.house && page.house.local === true) && (api.error !== "" || api.offline) }

            Rectangle {
                x: Theme.horizontalPageMargin
                width: Theme.itemSizeSmall
                height: Theme.paddingSmall
                radius: height / 2
                visible: page.note && U.str(page.note.color) !== ""
                color: page.note && U.str(page.note.color) !== "" ? page.note.color : "transparent"
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                textFormat: Text.RichText
                text: page.note ? Md.toRich(U.str(page.note.content), FiatPenusTheme.accent,
                                            FiatPenusTheme.secondaryText) : ""
                color: FiatPenusTheme.primaryText
                font.pixelSize: Theme.fontSizeSmall
                onLinkActivated: Qt.openUrlExternally(link)
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: page.note && U.str(page.note.content) === ""
                text: qsTr("Only a title.")
                color: FiatPenusTheme.secondaryText
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
                font.family: FiatPenusTheme.serif
            }

            Item { width: 1; height: Theme.paddingLarge }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                visible: page.note !== undefined && page.note !== null
                text: !page.note ? ""
                    : U.str(page.note.createdBy) === "" ? qsTr("Changed %1").arg(U.shortDate(page.note.updatedAt))
                    : qsTr("Written by %1 · changed %2").arg(U.str(page.note.createdBy)).arg(U.shortDate(page.note.updatedAt))
                color: FiatPenusTheme.secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }

        VerticalScrollDecorator { }
    }

    ActivityLine { running: api.busy > 0 && !(page.house && page.house.local === true) }
}
