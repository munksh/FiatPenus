import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../js/util.js" as U

// The pull-down on every side of the front page. The house rule's order:
// About, the colours, then the app's own, with what belongs to one side
// shown only there.
PullDownMenu {
    id: menu

    property Item host

    readonly property var house: host ? host.house : null
    readonly property string mode: host ? host.mode : "lists"

    highlightColor: FiatPenusTheme.chromeAccent
    busy: host !== null && host.refreshAsked

    MenuItem {
        text: qsTr("About")
        color: FiatPenusTheme.primaryText
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutPage.qml"))
    }
    MenuItem {
        text: FiatPenusTheme.ambient ? qsTr("Fiat colours") : qsTr("Follow ambience")
        color: FiatPenusTheme.primaryText
        onClicked: FiatPenusTheme.setAmbient(!FiatPenusTheme.ambient)
    }
    MenuItem {
        text: qsTr("Nextcloud")
        color: FiatPenusTheme.primaryText
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/SignInPage.qml"))
    }
    MenuItem {
        visible: menu.host !== null && menu.host.remote
        text: qsTr("Households")
        color: FiatPenusTheme.primaryText
        onClicked: menu.host.openHouses()
    }
    MenuItem {
        visible: menu.host !== null && menu.host.remote && !menu.host.local
        text: qsTr("Refresh")
        color: FiatPenusTheme.primaryText
        onClicked: menu.host.refreshFromMenu()
    }
    MenuItem {
        visible: menu.mode === "lists" && menu.host !== null && menu.host.agendaWaiting
        text: qsTr("Bring in lists from fiat agenda")
        color: FiatPenusTheme.primaryText
        onClicked: menu.host.importFromAgenda()
    }
    MenuItem {
        visible: menu.mode === "lists" && menu.house !== null && U.can(menu.house, "canCreateLists")
        text: qsTr("New list")
        color: FiatPenusTheme.primaryText
        onClicked: menu.host.openListDialog(null)
    }
    MenuItem {
        visible: menu.mode === "notes" && menu.house !== null && U.can(menu.house, "canCreateNotes")
        text: qsTr("New note")
        color: FiatPenusTheme.primaryText
        onClicked: menu.host.newNote()
    }
    MenuItem {
        visible: menu.mode === "photos" && menu.house !== null && U.can(menu.house, "canMovePhotos")
        text: qsTr("New folder")
        color: FiatPenusTheme.primaryText
        onClicked: menu.host.newFolder()
    }
    MenuItem {
        visible: menu.mode === "photos" && menu.house !== null && U.can(menu.house, "canUploadPhotos")
        text: qsTr("Add a photo")
        color: FiatPenusTheme.primaryText
        onClicked: menu.host.addPhoto()
    }
}
