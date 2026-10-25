import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

Page {
    id: page

    // Set when the server stopped accepting the app password.
    property bool expired: false
    property string message: ""

    readonly property bool checking: account.signedIn && (account.pantryState === "checking" || account.pantryState === "unknown")

    function paint() { FiatPenusTheme.applyPalette(page) }
    Component.onCompleted: {
        paint()
        if (page.expired) {
            serverField.text = account.server.replace(/^https:\/\//, "")
            page.message = qsTr("The server no longer accepts this phone's sign-in. Sign in again.")
            account.signOut()
        } else if (account.signedIn) {
            account.checkPantry()
        }
    }
    Connections { target: FiatPenusTheme; onAmbientChanged: page.paint() }

    function start() {
        page.message = ""
        account.startLogin(serverField.text)
    }

    // Back to the front page, which brings the server's households in beside
    // the phone's own.
    function goHome() {
        if (pageStack.currentPage === page)
            pageStack.pop()
    }

    Connections {
        target: account
        onLoginUrlReady: Qt.openUrlExternally(url)
        onLoginFailed: page.message = message
        onSignedInNow: account.checkPantry()
        onPantryChanged: {
            if (account.signedIn && account.pantryState === "present" && page.status === PageStatus.Active)
                page.goHome()
        }
    }

    FiatBackground { }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            highlightColor: FiatPenusTheme.chromeAccent

            MenuItem {
                text: qsTr("About")
                color: FiatPenusTheme.primaryText
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: FiatPenusTheme.ambient ? qsTr("Fiat colours") : qsTr("Follow ambience")
                color: FiatPenusTheme.primaryText
                onClicked: FiatPenusTheme.setAmbient(!FiatPenusTheme.ambient)
            }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            Item {
                width: parent.width
                height: FiatPenusTheme.statusRowCenter + wordmark.height / 2 + Theme.paddingMedium
                Text {
                    id: wordmark
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
            }

            Item { width: 1; height: Theme.paddingLarge }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                text: qsTr("The household's lists, notes and photos, from your own Nextcloud.")
                color: FiatPenusTheme.primaryText
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatPenusTheme.serif
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                text: qsTr("fiat penus works with Pantry, an app on your Nextcloud server. Sign in with your Nextcloud account: the browser opens for it, and the phone gets an app password of its own.")
                color: FiatPenusTheme.secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            Item { width: 1; height: Theme.paddingLarge }

            // ---- signing in ----
            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                visible: !account.signedIn

                TextField {
                    id: serverField
                    width: parent.width
                    label: qsTr("Nextcloud address")
                    placeholderText: qsTr("cloud.example.com")
                    inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    enabled: !account.waiting && !account.starting
                    EnterKey.enabled: text.trim() !== ""
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: { focus = false; page.start() }
                }

                FiatButton {
                    visible: !account.waiting
                    text: qsTr("sign in")
                    enabled: serverField.text.trim() !== "" && !account.starting
                    onClicked: { serverField.focus = false; page.start() }
                }

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: BusySize.Medium
                    running: account.starting || account.waiting
                    visible: running
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: account.waiting
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Sign in and allow access in the browser, then come back here. The phone is waiting for the server's answer.")
                    color: FiatPenusTheme.primaryText
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: FiatPenusTheme.serif
                    font.italic: true
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingLarge
                    visible: account.waiting
                    LinkText {
                        text: qsTr("open the page again")
                        onClicked: Qt.openUrlExternally(account.loginUrl)
                    }
                    LinkText {
                        text: qsTr("cancel")
                        color: FiatPenusTheme.secondaryText
                        onClicked: account.cancelLogin()
                    }
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: page.message !== ""
                    wrapMode: Text.WordWrap
                    text: page.message
                    color: FiatPenusTheme.wrong
                    font.pixelSize: Theme.fontSizeSmall
                }

                Item { width: 1; height: Theme.paddingLarge }

                LinkText {
                    x: Theme.horizontalPageMargin - Theme.paddingSmall
                    visible: !account.waiting
                    text: qsTr("sign in with an app password instead")
                    onClicked: {
                        var d = pageStack.push(Qt.resolvedUrl("AppPasswordDialog.qml"), { "server": serverField.text })
                        d.accepted.connect(function () {
                            page.message = ""
                            serverField.text = d.server
                            account.loginWithAppPassword(d.server, d.loginName, d.appPassword)
                        })
                    }
                }
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: !account.waiting
                    wrapMode: Text.WordWrap
                    text: qsTr("For a server the browser cannot reach, or a self-signed certificate the browser refuses.")
                    color: FiatPenusTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            // ---- signed in: looking for Pantry ----
            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                visible: account.signedIn

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.WordWrap
                    text: qsTr("Signed in as %1 on %2.").arg(account.displayName).arg(account.server.replace(/^https?:\/\//, ""))
                    color: FiatPenusTheme.primaryText
                    font.pixelSize: Theme.fontSizeSmall
                }

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: BusySize.Medium
                    running: page.checking
                    visible: running
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.WordWrap
                    color: account.pantryState === "missing" || account.pantryState === "unreachable"
                           ? FiatPenusTheme.wrong : FiatPenusTheme.secondaryText
                    font.pixelSize: Theme.fontSizeSmall
                    text: {
                        switch (account.pantryState) {
                        case "missing":
                            return qsTr("Pantry is not installed on this server. Someone with admin rights can add it from the Nextcloud app store.")
                        case "unreachable":
                            return qsTr("The server cannot be reached right now.")
                        case "present":
                            return qsTr("Pantry %1 found.").arg(account.pantryVersion)
                        default:
                            return qsTr("Looking for Pantry on the server…")
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingLarge
                    visible: !page.checking
                    LinkText {
                        visible: account.pantryState === "present"
                        text: qsTr("continue")
                        onClicked: page.goHome()
                    }
                    LinkText {
                        visible: account.pantryState !== "present"
                        text: qsTr("try again")
                        onClicked: account.checkPantry()
                    }
                    LinkText {
                        text: qsTr("sign out")
                        color: FiatPenusTheme.secondaryText
                        onClicked: account.signOut()
                    }
                }
            }
        }

        VerticalScrollDecorator { }
    }
}
