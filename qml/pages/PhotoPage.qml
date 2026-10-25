import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"
import "../js/util.js" as U
import "../js/shelf.js" as Shelf

// The photos one at a time, swiped sideways, with the caption under them.
Page {
    id: page

    property var house
    property var photos: []
    property int startIndex: 0
    property var folders: []

    signal changed()

    readonly property string base: "/houses/" + (house ? house.id : 0) + "/photos"
    readonly property var current: slides.currentIndex >= 0 && slides.currentIndex < photos.length
                                   ? photos[slides.currentIndex] : null
    readonly property bool editable: current !== null && current.canEdit !== false

    function paint() { FiatPenusTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections { target: FiatPenusTheme; onAmbientChanged: page.paint() }

    function replace(photo) {
        var at = slides.currentIndex
        photos = U.replaceById(photos, photo)
        slides.currentIndex = at
        changed()
    }

    function editCaption() {
        var photo = current
        var d = pageStack.push(Qt.resolvedUrl("TextDialog.qml"), {
            "title": qsTr("caption"), "label": qsTr("Caption"), "value": U.str(photo.caption), "allowEmpty": true })
        d.accepted.connect(function () {
            Shelf.send("PATCH", page.base + "/" + photo.id, { "caption": d.value }, function (ok, data) {
                if (ok && data && data.id) page.replace(data)
            })
        })
    }

    function move() {
        var photo = current
        var p = pageStack.push(Qt.resolvedUrl("FolderPickerPage.qml"), {
            "folders": page.folders, "selectedId": U.num(photo.folderId) })
        p.picked.connect(function (id) {
            Shelf.send("PATCH", page.base + "/" + photo.id, { "folderId": id }, function (ok, data) {
                if (ok && data && data.id) page.replace(data)
            })
        })
    }

    function remove() {
        var photo = current
        var at = slides.currentIndex
        Shelf.send("DELETE", base + "/" + photo.id, undefined, function (ok) { if (ok) page.changed() })
        photos = U.removeById(photos, photo.id)
        if (photos.length === 0) {
            pageStack.pop()
            return
        }
        slides.currentIndex = Math.min(at, photos.length - 1)
    }

    RemorsePopup { id: remorse }

    FiatBackground { }

    PageHead {
        id: head
        title: qsTr("%1 of %2").arg(slides.currentIndex + 1).arg(page.photos.length)
    }

    SlideshowView {
        id: slides
        anchors.top: head.bottom
        anchors.bottom: panel.top
        anchors.bottomMargin: Theme.paddingMedium
        width: parent.width
        itemWidth: width
        itemHeight: height
        model: page.photos
        Component.onCompleted: currentIndex = page.startIndex

        delegate: Item {
            width: slides.itemWidth
            height: slides.itemHeight

            Image {
                id: picture
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize.width: 2048
                sourceSize.height: 2048
                source: Shelf.imageUrl(page.base + "/" + modelData.id + "/preview", { "size": 2048 })
                opacity: status === Image.Ready ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { } }
            }
            BusyIndicator {
                anchors.centerIn: parent
                size: BusySize.Medium
                running: picture.status === Image.Loading
                visible: running
            }
            Label {
                anchors.centerIn: parent
                visible: picture.status === Image.Error
                text: page.house && page.house.local === true ? qsTr("This photo is no longer in Gallery.") : qsTr("The photo did not load.")
                color: FiatPenusTheme.secondaryText
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
                font.family: FiatPenusTheme.serif
            }
        }
    }

    Column {
        id: panel
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        width: parent.width
        spacing: Theme.paddingSmall

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            visible: text !== ""
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: page.current ? U.str(page.current.caption) : ""
            color: FiatPenusTheme.primaryText
            font.pixelSize: Theme.fontSizeMedium
            font.family: FiatPenusTheme.serif
        }
        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            horizontalAlignment: Text.AlignHCenter
            text: !page.current ? ""
                : U.str(page.current.uploadedBy) === "" ? U.shortDate(page.current.createdAt)
                : qsTr("%1 · %2").arg(U.str(page.current.uploadedBy)).arg(U.shortDate(page.current.createdAt))
            color: FiatPenusTheme.secondaryText
            font.pixelSize: Theme.fontSizeExtraSmall
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingLarge
            LinkText {
                visible: page.editable
                text: qsTr("caption")
                onClicked: page.editCaption()
            }
            LinkText {
                visible: page.editable && U.can(page.house, "canMovePhotos")
                text: qsTr("move")
                onClicked: page.move()
            }
            LinkText {
                visible: page.current !== null && U.can(page.house, "canDeletePhotos")
                text: qsTr("delete")
                color: FiatPenusTheme.secondaryText
                onClicked: remorse.execute(qsTr("Deleting"), function () { page.remove() })
            }
        }
    }

    ActivityLine { running: api.busy > 0 && !(page.house && page.house.local === true) }
}
