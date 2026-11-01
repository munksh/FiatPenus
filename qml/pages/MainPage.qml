import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import Nemo.Configuration 1.0
import ".."
import "../components"
import "../js/util.js" as U
import "../js/markdown.js" as Md
import "../js/shelf.js" as Shelf
import "../js/storage.js" as Storage

// The front page: one household at a time, in three sides -- its lists, the
// notes on its wall and its photo board. The first household is the phone's
// own and needs nothing; the others come from Pantry on Nextcloud, where
// everyone in the household sees the same things.
Page {
    id: page

    // ---- which side ----
    readonly property string mode: modeConfig.value === "notes" || modeConfig.value === "photos" ? modeConfig.value : "lists"
    function setMode(m) { modeConfig.value = m }
    ConfigurationValue {
        id: modeConfig
        key: "/apps/harbour-fiatpenus/mode"
        defaultValue: "lists"
    }

    // ---- which household ----
    property var houses: []
    property var house: null
    property bool loaded: false
    property bool refreshAsked: false

    readonly property int houseId: house ? house.id : 0
    readonly property string base: "/houses/" + houseId
    readonly property bool remote: account.signedIn && account.pantryState === "present"
    readonly property bool local: house !== null && house.local === true
    readonly property var phone: Shelf.localHouse(qsTr("This phone"), qsTr("Only on this phone, not shared."))

    ConfigurationValue {
        id: lastHouse
        key: "/apps/harbour-fiatpenus/house"
        defaultValue: 0
    }

    // ---- what is in it ----
    property var lists: []
    property var counts: ({})
    property int openTotal: 0
    property int doneTotal: 0
    property var notes: []
    property var photos: []
    property var folders: []
    property int uploading: 0
    property string photoProblem: ""
    Timer { id: problemTimer; interval: 6000; onTriggered: page.photoProblem = "" }

    // ---- lists from fiat agenda ----
    // Agenda 2.0 kept lists of its own on the phone. Agenda 2.1 saves them in
    // Documents; they come in here, into the phone's household.
    readonly property string agendaFile: "fiat-agenda-lists.json"
    property bool agendaWaiting: false
    property string listsNote: ""
    Timer { id: listsNoteTimer; interval: 8000; onTriggered: page.listsNote = "" }

    function lookForAgenda() { agendaWaiting = files.documentExists(agendaFile) }

    function importFromAgenda() {
        var data = null
        try { data = JSON.parse(files.readDocument(agendaFile)) } catch (e) { data = null }
        var got = data ? Storage.importShelf(data) : null
        if (got === null) {
            listsNote = qsTr("The file from fiat agenda could not be read")
        } else {
            files.retireDocument(agendaFile)
            listsNote = got.lists === 1 ? qsTr("1 list from fiat agenda")
                                        : qsTr("%1 lists from fiat agenda").arg(got.lists)
            if (!local) setHouse(phone, true)
            loadHouse(false)
        }
        listsNoteTimer.restart()
        lookForAgenda()
    }

    readonly property var loosePhotos: {
        var out = []
        for (var i = 0; i < photos.length; ++i)
            if (U.num(photos[i].folderId) === 0)
                out.push(photos[i])
        return out
    }

    allowedOrientations: defaultAllowedOrientations

    function paint() { FiatPenusTheme.applyPalette(page) }
    Component.onCompleted: {
        paint()
        refresh(false)
    }
    Connections { target: FiatPenusTheme; onAmbientChanged: page.paint() }

    property bool seenOnce: false
    onStatusChanged: {
        if (status !== PageStatus.Active)
            return
        if (seenOnce)
            loadHouse(false)
        seenOnce = true
        lookForAgenda()
    }
    onRemoteChanged: refresh(false)

    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive && page.status === PageStatus.Active && page.houseId !== 0)
                page.loadHouse(false)
        }
    }

    // ---- loading ----

    function refreshFromMenu() {
        refreshAsked = true
        refresh(true, function () { page.refreshAsked = false })
    }

    // The household list first; the household's own things follow from it.
    // finished, when given, is called once everything asked for has answered.
    function refresh(again, finished) {
        var done = finished || function () { }
        if (!remote) {
            loaded = true
            if (!showHouses([]) || again)
                loadHouse(false, done)
            else
                done()
            return
        }
        if (houses.length <= 1) {
            var c = Shelf.cached("/houses", {})
            showHouses(c !== undefined ? c : [])
        }
        Shelf.get("/houses", {}, function (ok, data) {
            page.loaded = true
            if (!ok) {
                if (page.houses.length === 0)
                    page.showHouses([])
                done()
                return
            }
            if (!page.showHouses(data) || again)
                page.loadHouse(false, done)
            else
                done()
        })
    }

    // The phone's household first, then the server's. Someone who never chose
    // gets the server's first household, the one they came for.
    function showHouses(data) {
        houses = [phone].concat(U.asArray(data))
        var want = Number(lastHouse.value) || 0
        var h = U.byId(houses, want)
        if (!h)
            h = houses.length > 1 && want === 0 ? houses[1] : phone
        return setHouse(h, false)
    }

    // Returns whether a different household is now shown. Only a choice made
    // by hand is remembered: falling back to the phone while signed out must
    // not forget which household you use.
    function setHouse(h, chosen) {
        var changed = (house === null) !== (h === null) || (house !== null && h !== null && house.id !== h.id)
        house = h
        if (!h)
            return changed
        if (chosen && Number(lastHouse.value) !== h.id)
            lastHouse.value = h.id
        if (changed) {
            lists = []
            counts = {}
            openTotal = 0
            doneTotal = 0
            notes = []
            photos = []
            folders = []
            loadHouse(true)
        }
        return changed
    }

    function loadHouse(withCache, finished) {
        var done = finished || function () { }
        if (houseId === 0) {
            done()
            return
        }
        var want = []
        if (U.can(house, "canViewLists")) {
            want.push([base + "/lists", { "limit": 100 }, function (data) { page.lists = U.asArray(data) }])
            want.push([base + "/items", { "limit": 1000 }, function (data) { page.countItems(U.asArray(data)) }])
        }
        if (U.can(house, "canViewNotes"))
            want.push([base + "/notes", { "limit": 100 }, function (data) { page.showNotes(data) }])
        if (U.can(house, "canViewPhotos")) {
            want.push([base + "/photos", { "limit": 1000 }, function (data) { page.photos = U.asArray(data) }])
            want.push([base + "/photos/folders", { "limit": 100 }, function (data) { page.folders = U.asArray(data) }])
        }
        var left = want.length
        if (left === 0) {
            done()
            return
        }
        var forHouse = houseId
        want.forEach(function (w) {
            if (withCache) {
                var c = Shelf.cached(w[0], w[1])
                if (c !== undefined) w[2](c)
            }
            Shelf.get(w[0], w[1], function (ok, data) {
                if (ok && forHouse === page.houseId) w[2](data)
                if (--left === 0) done()
            })
        })
    }

    function countItems(items) {
        var c = {}, open = 0, done = 0
        for (var i = 0; i < items.length; ++i) {
            var it = items[i]
            if (!c[it.listId])
                c[it.listId] = { "open": 0, "done": 0 }
            if (it.done) { c[it.listId].done++; done++ }
            else { c[it.listId].open++; open++ }
        }
        counts = c
        openTotal = open
        doneTotal = done
    }

    function showNotes(data) {
        var all = U.asArray(data).slice(0)
        all.sort(function (a, b) {
            if (a.isPinned !== b.isPinned) return a.isPinned ? -1 : 1
            return U.num(a.sortOrder) - U.num(b.sortOrder)
        })
        notes = all
    }

    // ---- households ----

    function openHouses() {
        var p = pageStack.push(Qt.resolvedUrl("HousesPage.qml"), { "houses": page.houses.slice(1), "currentId": page.houseId })
        p.chosen.connect(function (h) { page.setHouse(h, true) })
        p.created.connect(function (h) { page.houses = page.houses.concat([h]); page.setHouse(h, true) })
    }

    // ---- lists ----

    function saveList(listId, fields) {
        var done = function (ok, data) {
            if (ok) {
                page.lists = U.replaceById(page.lists, data)
                page.loadHouse(false)
            }
        }
        if (listId > 0)
            Shelf.send("PATCH", base + "/lists/" + listId, fields, done)
        else
            Shelf.send("POST", base + "/lists", fields, done)
    }

    function deleteList(listId) {
        lists = U.removeById(lists, listId)
        Shelf.send("DELETE", base + "/lists/" + listId, undefined, function () { page.loadHouse(false) })
    }

    function openListDialog(list) {
        var d = pageStack.push(Qt.resolvedUrl("ListDialog.qml"), list ? {
            "listId": list.id, "name": U.str(list.name), "description": U.str(list.description), "colour": U.str(list.color)
        } : {})
        d.accepted.connect(function () { page.saveList(d.listId, d.fields()) })
    }

    // ---- notes ----

    function newNote() {
        var d = pageStack.push(Qt.resolvedUrl("NoteDialog.qml"))
        d.accepted.connect(function () {
            var body = d.fields()
            if (body.content === "") delete body.content
            if (body.color === "") delete body.color
            Shelf.send("POST", page.base + "/notes", body, function (ok) { if (ok) page.loadHouse(false) })
        })
    }

    function editNote(note) {
        var d = pageStack.push(Qt.resolvedUrl("NoteDialog.qml"), {
            "noteId": note.id, "title": U.str(note.title), "content": U.str(note.content), "colour": U.str(note.color) })
        d.accepted.connect(function () {
            Shelf.send("PATCH", page.base + "/notes/" + note.id, d.fields(), function (ok) { if (ok) page.loadHouse(false) })
        })
    }

    function pinNote(note) {
        Shelf.send("PATCH", base + "/notes/" + note.id, { "isPinned": !note.isPinned }, function (ok) { if (ok) page.loadHouse(false) })
    }

    function removeNote(id) {
        notes = U.removeById(notes, id)
        Shelf.send("DELETE", base + "/notes/" + id, undefined, function () { page.loadHouse(false) })
    }

    // ---- photos ----

    function addPhoto() { pageStack.push(pickerComponent) }

    function upload(url) {
        uploading++
        Shelf.upload(base + "/photos", url, {}, function (ok) {
            page.uploading = Math.max(0, page.uploading - 1)
            if (ok) {
                page.photoProblem = ""
                page.loadHouse(false)
            } else if (page.local) {
                page.photoProblem = qsTr("That file cannot be shown here")
                problemTimer.restart()
            }
        })
    }

    function askName(title, value, done) {
        var d = pageStack.push(Qt.resolvedUrl("TextDialog.qml"), { "title": title, "value": value, "label": qsTr("Name") })
        d.accepted.connect(function () { done(d.value) })
    }

    function newFolder() {
        askName(qsTr("a new folder"), "", function (name) {
            Shelf.send("POST", page.base + "/photos/folders", { "name": name }, function (ok) { if (ok) page.loadHouse(false) })
        })
    }

    function renameFolder(id, name) {
        askName(qsTr("folder"), name, function (value) {
            Shelf.send("PATCH", page.base + "/photos/folders/" + id, { "name": value }, function (ok) { if (ok) page.loadHouse(false) })
        })
    }

    function deleteFolder(id) {
        folders = U.removeById(folders, id)
        Shelf.send("DELETE", base + "/photos/folders/" + id, undefined, function () { page.loadHouse(false) })
    }

    function countIn(id) {
        var n = 0
        for (var i = 0; i < photos.length; ++i)
            if (U.num(photos[i].folderId) === id) ++n
        return n
    }

    Component {
        id: pickerComponent
        ImagePickerPage {
            onSelectedContentChanged: page.upload(String(selectedContent))
        }
    }

    // ---- paper ----

    FiatBackground { }

    // ================================================================ lists ==

    SilicaListView {
        id: listsView
        anchors.fill: parent
        visible: page.mode === "lists"
        model: page.lists
        clip: true

        FrontMenu { host: page }

        header: HouseHead {
            width: listsView.width
            mode: page.mode
            refreshing: page.refreshAsked
            houses: page.houses
            house: page.house
            figure: String(page.openTotal)
            title: page.openTotal === 0 ? qsTr("nothing to fix")
                 : page.openTotal === 1 ? qsTr("thing to fix") : qsTr("things to fix")
            showRing: true
            details: page.listsNote !== "" ? [page.listsNote] : []
            done: page.doneTotal
            total: page.doneTotal + page.openTotal
            onModeChosen: page.setMode(mode)
            onHouseChosen: page.setHouse(house, true)
        }

        delegate: ListItem {
            id: row
            readonly property var c: page.counts[modelData.id]
            readonly property int open: c ? c.open : -1
            readonly property int done: c ? c.done : 0
            width: listsView.width
            contentHeight: Math.max(Theme.itemSizeMedium, rowCol.height + 2 * Theme.paddingMedium)
            highlightedColor: FiatPenusTheme.highlightWash
            onClicked: pageStack.push(Qt.resolvedUrl("ListPage.qml"), { "house": page.house, "list": modelData })
            menu: Component {
                ContextMenu {
                    backgroundColor: FiatPenusTheme.highlightWash
                    highlightColor: FiatPenusTheme.accent
                    MenuItem {
                        visible: modelData.canEdit !== false && U.can(page.house, "canEditLists")
                        text: qsTr("edit")
                        color: FiatPenusTheme.primaryText
                        onClicked: page.openListDialog(modelData)
                    }
                    MenuItem {
                        visible: U.can(page.house, "canDeleteLists")
                        text: qsTr("delete")
                        color: FiatPenusTheme.wrong
                        onClicked: {
                            var id = modelData.id
                            row.remorseDelete(function () { page.deleteList(id) })
                        }
                    }
                }
            }

            // The name and what is left, then a bar in the list's own colour
            // for how far it has got. The bar is the separation.
            Column {
                id: rowCol
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingSmall

                Item {
                    width: parent.width
                    height: nameLabel.height
                    Label {
                        id: nameLabel
                        anchors.left: parent.left
                        anchors.right: note.left
                        anchors.rightMargin: Theme.paddingMedium
                        text: U.str(modelData.name)
                        truncationMode: TruncationMode.Fade
                        color: row.highlighted ? FiatPenusTheme.accent : FiatPenusTheme.primaryText
                        font.family: FiatPenusTheme.serif
                        font.pixelSize: Theme.fontSizeMedium
                    }
                    Label {
                        id: note
                        anchors.right: parent.right
                        anchors.baseline: nameLabel.baseline
                        visible: row.open >= 0
                        text: row.open > 0 ? qsTr("%1 of %2 left").arg(row.open).arg(row.open + row.done)
                            : row.done > 0 ? qsTr("all done") : qsTr("empty")
                        color: row.open > 0 ? FiatPenusTheme.accent : FiatPenusTheme.secondaryText
                        font.family: FiatPenusTheme.serif
                        font.italic: row.open <= 0
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    text: U.str(modelData.description)
                    truncationMode: TruncationMode.Fade
                    color: FiatPenusTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Rectangle {
                    width: parent.width
                    height: Math.max(3, Math.round(Theme.paddingSmall * 0.7))
                    radius: height / 2
                    color: FiatPenusTheme.hairline
                    Rectangle {
                        readonly property int total: Math.max(0, row.open) + row.done
                        width: total > 0 ? parent.width * row.done / total : 0
                        height: parent.height
                        radius: parent.radius
                        color: U.str(modelData.color) !== "" ? modelData.color : FiatPenusTheme.secondaryText
                    }
                }
            }
        }

        footer: Column {
            width: listsView.width
            visible: page.house !== null

            Item { width: 1; height: Theme.paddingMedium }
            LinkText {
                x: Theme.horizontalPageMargin - Theme.paddingSmall
                visible: U.can(page.house, "canCreateLists")
                text: page.lists.length === 0 ? qsTr("No lists yet. Add one") : qsTr("Add a list")
                onClicked: page.openListDialog(null)
            }
            ShareNote { host: page }
        }

        VerticalScrollDecorator { }
    }

    // ================================================================ notes ==

    SilicaListView {
        id: notesView
        anchors.fill: parent
        visible: page.mode === "notes"
        model: page.notes
        spacing: Theme.paddingMedium
        clip: true

        FrontMenu { host: page }

        header: HouseHead {
            width: notesView.width
            mode: page.mode
            refreshing: page.refreshAsked
            houses: page.houses
            house: page.house
            figure: String(page.notes.length)
            title: page.notes.length === 0 ? qsTr("nothing on the wall")
                 : page.notes.length === 1 ? qsTr("note on the wall") : qsTr("notes on the wall")
            onModeChosen: page.setMode(mode)
            onHouseChosen: page.setHouse(house, true)
        }

        delegate: ListItem {
            id: noteRow
            readonly property string colour: U.str(modelData.color)
            readonly property bool editable: modelData.canEdit !== false
            width: notesView.width
            contentHeight: card.height
            highlightedColor: "transparent"
            onClicked: {
                var p = pageStack.push(Qt.resolvedUrl("NotePage.qml"), { "house": page.house, "note": modelData })
                p.changed.connect(function () { page.loadHouse(false) })
                p.removed.connect(function (id) { page.removeNote(id) })
            }
            menu: Component {
                ContextMenu {
                    backgroundColor: FiatPenusTheme.highlightWash
                    highlightColor: FiatPenusTheme.accent
                    MenuItem {
                        visible: noteRow.editable
                        text: modelData.isPinned ? qsTr("unpin") : qsTr("pin")
                        color: FiatPenusTheme.primaryText
                        onClicked: page.pinNote(modelData)
                    }
                    MenuItem {
                        visible: noteRow.editable
                        text: qsTr("edit")
                        color: FiatPenusTheme.primaryText
                        onClicked: page.editNote(modelData)
                    }
                    MenuItem {
                        visible: U.can(page.house, "canDeleteNotes")
                        text: qsTr("delete")
                        color: FiatPenusTheme.wrong
                        onClicked: {
                            var id = modelData.id
                            noteRow.remorseDelete(function () { page.removeNote(id) })
                        }
                    }
                }
            }

            Rectangle {
                id: card
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                height: cardCol.height + 2 * Theme.paddingLarge
                radius: FiatPenusTheme.cardRadius / 2
                color: noteRow.highlighted ? Qt.tint(FiatPenusTheme.card, FiatPenusTheme.highlightWash) : FiatPenusTheme.card
                border.width: 1
                border.color: FiatPenusTheme.innerBorder

                // The note's own colour, as a dot beside the title.
                Rectangle {
                    id: noteDot
                    visible: noteRow.colour !== ""
                    x: Theme.paddingLarge
                    y: Theme.paddingLarge + titleLabel.height / 2 - height / 2
                    width: Theme.paddingMedium * 1.2
                    height: width
                    radius: width / 2
                    color: noteRow.colour !== "" ? noteRow.colour : "transparent"
                }

                Column {
                    id: cardCol
                    x: Theme.paddingLarge + (noteDot.visible ? noteDot.width + Theme.paddingMedium : 0)
                    y: Theme.paddingLarge
                    width: parent.width - x - Theme.paddingLarge
                    spacing: Theme.paddingSmall

                    Item {
                        width: parent.width
                        height: Math.max(titleLabel.height, pinLabel.height)
                        Label {
                            id: titleLabel
                            width: parent.width - (pinLabel.visible ? pinLabel.width + Theme.paddingMedium : 0)
                            wrapMode: Text.WordWrap
                            text: U.str(modelData.title)
                            color: FiatPenusTheme.primaryText
                            font.pixelSize: Theme.fontSizeMedium
                            font.family: FiatPenusTheme.serif
                        }
                        Label {
                            id: pinLabel
                            anchors.right: parent.right
                            visible: modelData.isPinned === true
                            text: qsTr("pinned")
                            color: FiatPenusTheme.accent
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.italic: true
                            font.family: FiatPenusTheme.serif
                        }
                    }
                    Label {
                        width: parent.width
                        visible: text !== ""
                        wrapMode: Text.WordWrap
                        maximumLineCount: 6
                        elide: Text.ElideRight
                        text: Md.preview(modelData.content, 6)
                        color: FiatPenusTheme.secondaryText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }

        footer: Column {
            width: notesView.width
            visible: page.house !== null

            Item { width: 1; height: Theme.paddingMedium }
            LinkText {
                x: Theme.horizontalPageMargin - Theme.paddingSmall
                visible: U.can(page.house, "canCreateNotes")
                text: page.notes.length === 0 ? qsTr("The wall is empty. Add a note") : qsTr("Add a note")
                onClicked: page.newNote()
            }
            ShareNote { host: page }
        }

        VerticalScrollDecorator { }
    }

    // =============================================================== photos ==

    SilicaGridView {
        id: photosView
        anchors.fill: parent
        visible: page.mode === "photos"
        model: page.loosePhotos
        cellWidth: width / 3
        cellHeight: cellWidth
        clip: true

        FrontMenu { host: page }

        header: Column {
            width: photosView.width

            HouseHead {
                width: parent.width
                mode: page.mode
                refreshing: page.refreshAsked
                houses: page.houses
                house: page.house
                figure: String(page.photos.length)
                title: page.photos.length === 0 ? qsTr("nothing on the board")
                     : page.photos.length === 1 ? qsTr("photo on the board") : qsTr("photos on the board")
                details: page.uploading > 0 ? [qsTr("sending %n…", "", page.uploading)]
                       : page.photoProblem !== "" ? [page.photoProblem] : []
                onModeChosen: page.setMode(mode)
                onHouseChosen: page.setHouse(house, true)
            }

            Repeater {
                model: page.folders
                delegate: ListItem {
                    id: folderRow
                    width: photosView.width
                    contentHeight: Theme.itemSizeSmall
                    highlightedColor: FiatPenusTheme.highlightWash
                    onClicked: pageStack.push(Qt.resolvedUrl("PhotosPage.qml"), {
                        "house": page.house, "folderId": modelData.id, "folderName": U.str(modelData.name) })
                    menu: Component {
                        ContextMenu {
                            backgroundColor: FiatPenusTheme.highlightWash
                            highlightColor: FiatPenusTheme.accent
                            MenuItem {
                                visible: U.can(page.house, "canMovePhotos")
                                text: qsTr("rename")
                                color: FiatPenusTheme.primaryText
                                onClicked: page.renameFolder(modelData.id, U.str(modelData.name))
                            }
                            MenuItem {
                                visible: U.can(page.house, "canDeletePhotos")
                                text: qsTr("delete")
                                color: FiatPenusTheme.wrong
                                onClicked: {
                                    var id = modelData.id
                                    folderRow.remorseDelete(function () { page.deleteFolder(id) })
                                }
                            }
                        }
                    }
                    Label {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin - countLabel.width
                        text: U.str(modelData.name)
                        truncationMode: TruncationMode.Fade
                        color: folderRow.highlighted ? FiatPenusTheme.accent : FiatPenusTheme.primaryText
                        font.family: FiatPenusTheme.serif
                        font.pixelSize: Theme.fontSizeMedium
                    }
                    Label {
                        id: countLabel
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.countIn(modelData.id)
                        color: FiatPenusTheme.accent
                        font.family: FiatPenusTheme.serif
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        delegate: Item {
            width: photosView.cellWidth
            height: photosView.cellHeight

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
                source: Shelf.imageUrl(page.base + "/photos/" + modelData.id + "/preview", { "size": 256 })
                opacity: status === Image.Ready ? (tap.pressed ? 0.6 : 1.0) : 0.0
                Behavior on opacity { FadeAnimation { } }
            }
            MouseArea {
                id: tap
                anchors.fill: parent
                onClicked: {
                    var p = pageStack.push(Qt.resolvedUrl("PhotoPage.qml"), {
                        "house": page.house, "photos": page.loosePhotos, "startIndex": index, "folders": page.folders })
                    p.changed.connect(function () { page.loadHouse(false) })
                }
            }
        }

        footer: Column {
            width: photosView.width
            visible: page.house !== null

            Item { width: 1; height: Theme.paddingMedium }
            LinkText {
                x: Theme.horizontalPageMargin - Theme.paddingSmall
                visible: U.can(page.house, "canUploadPhotos")
                text: page.photos.length === 0 ? qsTr("The board is empty. Add a photo") : qsTr("Add a photo")
                onClicked: page.addPhoto()
            }
            ShareNote { host: page }
        }

        VerticalScrollDecorator { }
    }

    ActivityLine { running: api.busy > 0 && !page.refreshAsked }
}
