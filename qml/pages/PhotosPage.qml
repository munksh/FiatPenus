import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import ".."
import "../components"
import "../js/util.js" as U
import "../js/shelf.js" as Shelf

// One folder of the photo board: a grid of its pictures. The board itself,
// with its folders and loose photos, is a side of the front page.
Page {
    id: page

    property var house
    property int folderId: 0
    property string folderName: ""

    property var photos: []
    property var folders: []
    property bool loaded: false
    property bool seenOnce: false
    property int uploading: 0

    readonly property string base: "/houses/" + (house ? house.id : 0) + "/photos"
    readonly property bool local: house !== null && house !== undefined && house.local === true
    readonly property var shown: {
        var out = []
        for (var i = 0; i < photos.length; ++i)
            if (U.num(photos[i].folderId) === folderId)
                out.push(photos[i])
        return out
    }

    function paint() { FiatPenusTheme.applyPalette(page) }
    Component.onCompleted: {
        paint()
        var cp = Shelf.cached(base, { "limit": 1000 })
        if (cp !== undefined) photos = U.asArray(cp)
        var cf = Shelf.cached(base + "/folders", { "limit": 100 })
        if (cf !== undefined) folders = U.asArray(cf)
        load()
    }
    Connections { target: FiatPenusTheme; onAmbientChanged: page.paint() }

    onStatusChanged: {
        if (status !== PageStatus.Active)
            return
        if (seenOnce)
            load()
        seenOnce = true
    }

    function load() {
        Shelf.get(base, { "limit": 1000 }, function (ok, data) {
            page.loaded = true
            if (ok) page.photos = U.asArray(data)
        })
        Shelf.get(base + "/folders", { "limit": 100 }, function (ok, data) {
            if (ok) page.folders = U.asArray(data)
        })
    }

    function upload(url) {
        uploading++
        Shelf.upload(base, url, { "folderId": folderId }, function (ok) {
            page.uploading = Math.max(0, page.uploading - 1)
            if (ok) page.load()
        })
    }

    function rename() {
        var d = pageStack.push(Qt.resolvedUrl("TextDialog.qml"), { "title": qsTr("folder"), "value": folderName, "label": qsTr("Name") })
        d.accepted.connect(function () {
            var value = d.value
            Shelf.send("PATCH", page.base + "/folders/" + page.folderId, { "name": value }, function (ok) {
                if (ok) page.folderName = value
            })
        })
    }

    Component {
        id: pickerComponent
        ImagePickerPage {
            onSelectedContentChanged: page.upload(String(selectedContent))
        }
    }

    RemorsePopup { id: remorse }

    FiatBackground { }

    SilicaGridView {
        id: grid
        anchors.fill: parent
        model: page.shown
        cellWidth: width / 3
        cellHeight: cellWidth

        PullDownMenu {
            highlightColor: FiatPenusTheme.chromeAccent
            MenuItem {
                visible: U.can(page.house, "canDeletePhotos")
                text: qsTr("Delete folder")
                color: FiatPenusTheme.primaryText
                onClicked: remorse.execute(qsTr("Deleting the folder"), function () {
                    var p = pageStack.previousPage(page)
                    var id = page.folderId
                    pageStack.pop()
                    if (p && p.deleteFolder) p.deleteFolder(id)
                })
            }
            MenuItem {
                visible: U.can(page.house, "canMovePhotos")
                text: qsTr("Rename folder")
                color: FiatPenusTheme.primaryText
                onClicked: page.rename()
            }
            MenuItem {
                visible: !page.local
                text: qsTr("Refresh")
                color: FiatPenusTheme.primaryText
                onClicked: page.load()
            }
            MenuItem {
                visible: U.can(page.house, "canUploadPhotos")
                text: qsTr("Add a photo")
                color: FiatPenusTheme.primaryText
                onClicked: pageStack.push(pickerComponent)
            }
        }

        header: Column {
            width: grid.width

            PageHead {
                title: page.folderName
                subtitle: page.uploading > 0 ? qsTr("sending %n…", "", page.uploading)
                                             : (page.house ? U.str(page.house.name) : "")
            }
            ErrorLine { visible: !page.local && (api.error !== "" || api.offline) }
            Item { width: 1; height: Theme.paddingMedium }
        }

        delegate: Item {
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: FiatPenusTheme.recessFill
            }
            Image {
                anchors.fill: parent
                anchors.margins: 1
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: width
                sourceSize.height: height
                source: Shelf.imageUrl(page.base + "/" + modelData.id + "/preview", { "size": 256 })
                opacity: status === Image.Ready ? (tap.pressed ? 0.6 : 1.0) : 0.0
                Behavior on opacity { FadeAnimation { } }
            }
            MouseArea {
                id: tap
                anchors.fill: parent
                onClicked: {
                    var p = pageStack.push(Qt.resolvedUrl("PhotoPage.qml"), {
                        "house": page.house, "photos": page.shown, "startIndex": index, "folders": page.folders })
                    p.changed.connect(function () { page.load() })
                }
            }
        }

        VerticalScrollDecorator { }
    }

    EmptyNote {
        anchors.centerIn: parent
        visible: page.loaded && page.shown.length === 0
        text: U.can(page.house, "canUploadPhotos") ? qsTr("No photos here. Pull down to add one.") : qsTr("No photos here.")
    }

    ActivityLine { running: api.busy > 0 && !page.local }
}
