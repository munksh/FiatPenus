import QtQuick 2.0
import Sailfish.Silica 1.0
import "."
import "pages"

ApplicationWindow {
    id: app

    // The phone's own household needs no account, so the front page is always
    // first; signing in is a page of its own, reached from the pull-down.
    initialPage: Qt.resolvedUrl("pages/MainPage.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.Portrait
    _defaultPageOrientations: Orientation.Portrait

    property bool sendingToSignIn: false

    function toSignIn() {
        if (sendingToSignIn || !account.signedIn)
            return
        sendingToSignIn = true
        pageStack.push(Qt.resolvedUrl("pages/SignInPage.qml"), { "expired": true })
    }

    Component.onCompleted: {
        FiatPenusTheme.applyPalette(app)
        if (account.signedIn)
            account.checkPantry()
    }
    Connections { target: FiatPenusTheme; onAmbientChanged: FiatPenusTheme.applyPalette(app) }

    // A revoked app password answers 401 to everything: back to signing in.
    Connections { target: api; onUnauthorized: app.toSignIn() }
    Connections {
        target: account
        onPantryChanged: if (account.pantryState === "unauthorized") app.toSignIn()
        onSignedInNow: app.sendingToSignIn = false
    }
}
