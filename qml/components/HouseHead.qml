import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../js/util.js" as U

// The top of every side of the front page: the wordmark and the three sides,
// the spinner for a refresh, the card with this side's figure, and the
// households as words underneath. The same on all three sides, so moving
// between them only changes what is under it.
Column {
    id: root

    property string mode: "lists"
    property bool refreshing: false
    property var houses: []
    property var house: null

    property string figure: ""
    property string title: ""
    property var details: []
    property int done: 0
    property int total: 0
    property bool showRing: false

    signal modeChosen(string mode)
    signal houseChosen(var house)

    width: parent ? parent.width : 0
    spacing: Theme.paddingMedium

    ModeHead {
        mode: root.mode
        onChosen: root.modeChosen(mode)
    }

    SyncSpinner { running: root.refreshing }

    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - Theme.horizontalPageMargin * 2
        // On the phone's own household a server that is away changes nothing,
        // so only a missing Pantry is worth saying there.
        visible: account.signedIn && account.pantryState !== "present" && account.pantryState !== "unknown"
                 && (root.house === null || root.house.local !== true || account.pantryState === "missing")
        wrapMode: Text.WordWrap
        text: account.pantryState === "missing"
              ? qsTr("Pantry is not installed on %1. Someone with admin rights can add it from the Nextcloud app store.").arg(account.server.replace(/^https?:\/\//, ""))
              : account.pantryState === "checking" ? qsTr("Looking for Pantry on the server…")
              : qsTr("The server cannot be reached right now.")
        color: account.pantryState === "checking" ? FiatPenusTheme.secondaryText : FiatPenusTheme.wrong
        font.pixelSize: Theme.fontSizeSmall
    }

    FaceCard {
        visible: root.house !== null
        figure: root.figure
        title: root.title
        details: root.details
        done: root.done
        total: root.total
        showRing: root.showRing
    }

    // In the place, and the size, of a row of choices: one word per
    // household, the one shown underlined.
    Column {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        visible: root.house !== null

        Flow {
            width: parent.width
            spacing: Theme.paddingSmall
            Repeater {
                model: root.houses
                Pill {
                    text: U.str(modelData.name)
                    pixelSize: FiatPenusTheme.navFontSize
                    selected: root.house !== null && modelData.id === root.house.id
                    onClicked: if (!selected) root.houseChosen(modelData)
                }
            }
        }
        Label {
            x: Theme.paddingMedium
            width: parent.width - Theme.paddingMedium
            visible: text !== ""
            text: root.house ? U.str(root.house.description) : ""
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            color: FiatPenusTheme.secondaryText
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }

    ErrorLine { visible: root.house !== null && root.house.local !== true && (api.error !== "" || api.offline) }

    Item { width: 1; height: Theme.paddingSmall }
}
