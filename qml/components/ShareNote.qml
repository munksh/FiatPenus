import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// Said once, quietly, where the phone's own household ends: sharing is what
// Nextcloud adds.
Column {
    id: root

    property Item host

    width: parent ? parent.width : 0
    readonly property bool wanted: host !== null && host.local && !account.signedIn

    Item { width: 1; height: Theme.paddingLarge; visible: root.wanted }
    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        visible: root.wanted
        wrapMode: Text.WordWrap
        text: qsTr("To share with your household, connect a Nextcloud with Pantry on it.")
        color: FiatPenusTheme.secondaryText
        font.pixelSize: Theme.fontSizeExtraSmall
    }
    LinkText {
        x: Theme.horizontalPageMargin - Theme.paddingSmall
        visible: root.wanted
        text: qsTr("Connect Nextcloud")
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/SignInPage.qml"))
    }
    Item { width: 1; height: Theme.paddingLarge }
}
