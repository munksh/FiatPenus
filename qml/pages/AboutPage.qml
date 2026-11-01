import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

Page {
    id: page

    function paint() { FiatPenusTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections { target: FiatPenusTheme; onAmbientChanged: page.paint() }

    FiatBackground { }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHead {
                title: qsTr("about")
                subtitle: "fiat penus"
            }

            Label {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatPenusTheme.serif
                color: FiatPenusTheme.primaryText
                text: qsTr("Milk, coffee, bin bags. Whoever passes the shop next has the list in their pocket.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPenusTheme.secondaryText
                text: qsTr("fiat penus keeps a household's lists, its notes wall and its photo board: lists with categories, quantities and things that come back. The phone has a household of its own that needs no account. Connect Nextcloud with Pantry on it and the households there come alongside, shared with everyone in them and kept on your own server.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPenusTheme.secondaryText
                text: qsTr("<b>fiat</b> — Latin, <i>let there be</i>. From <i>fiat lux</i> in the Vulgate: let there be light, and there was light. The first app took the phrase. The rest of the family kept the verb.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPenusTheme.secondaryText
                text: qsTr("<b>penus</b> — the household's store of food, what was put by. Its keepers were the Penates, the gods of the larder and the hearth, who took their name from it.")
            }

            Item { width: 1; height: Theme.paddingLarge }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatPenusTheme.innerBorder
            }
            Item { width: 1; height: Theme.paddingMedium }

            Column {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: FiatPenusTheme.serif
                    font.italic: true
                    color: FiatPenusTheme.primaryText
                    text: "Semper boni assiduique domini referta\ncella vinaria, olearia, etiam penaria est"
                }
                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: FiatPenusTheme.secondaryText
                    text: qsTr("A good and careful master's cellar is always full: of wine, of oil, and of provisions too.")
                }
                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: FiatPenusTheme.secondaryText
                    text: "Cicero, Cato Maior de Senectute 56"
                }
            }

            Item { width: 1; height: Theme.paddingMedium }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatPenusTheme.innerBorder
            }

            SectionLabel { x: Theme.horizontalPageMargin; text: qsTr("Built on") }

            BackgroundItem {
                width: content.width
                height: builtCol.height + 2 * Theme.paddingSmall
                highlightedColor: FiatPenusTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://github.com/chenasraf/nextcloud-pantry")
                Column {
                    id: builtCol
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        text: "Pantry"
                        color: FiatPenusTheme.primaryText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: qsTr("The Nextcloud app by Chen Asraf. fiat penus talks to its open API; it is not made by the Pantry project.")
                        color: FiatPenusTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            SectionLabel { x: Theme.horizontalPageMargin; text: qsTr("Your data") }

            Label {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPenusTheme.secondaryText
                text: qsTr("The phone's own household stays on the phone; its photos are not copied but shown from Gallery, so a photo deleted there leaves the board too. A Nextcloud household lives on your server and goes only between the phone and it; the phone keeps the last copy of each list, wall and board, so they show while offline.")
            }
            Label {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPenusTheme.secondaryText
                text: qsTr("Signing in makes an app password for this phone, kept in the app's settings file. It can be withdrawn in Nextcloud under Security, and signing out withdraws it.")
            }
            Label {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPenusTheme.secondaryText
                text: qsTr("Permissions: Internet, to reach your server; Pictures, Downloads and the memory card, to show or send a photo you choose; the media index, which the photo picker reads; and Documents, only to bring in the lists fiat agenda saved there.")
            }

            SectionLabel { x: Theme.horizontalPageMargin; text: qsTr("Made by") }

            Label {
                x: Theme.horizontalPageMargin
                text: "Munkstolen"
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatPenusTheme.serif
                color: FiatPenusTheme.primaryText
            }
            Label {
                x: Theme.horizontalPageMargin
                text: "Caesar Prometheus Ivarsson"
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPenusTheme.secondaryText
            }

            BackgroundItem {
                width: content.width
                height: Theme.itemSizeMedium
                highlightedColor: FiatPenusTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://munkstolen.se")
                Column {
                    x: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        text: "munkstolen.se"
                        color: FiatPenusTheme.primaryText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Label {
                        text: qsTr("Everything else I make")
                        color: FiatPenusTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            BackgroundItem {
                width: content.width
                height: Theme.itemSizeMedium
                highlightedColor: FiatPenusTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://github.com/munksh/FiatPenus")
                Column {
                    x: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        text: "github.com/munksh/FiatPenus"
                        color: FiatPenusTheme.primaryText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Label {
                        text: qsTr("Source and issues · MIT licence")
                        color: FiatPenusTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            // -- The family ---------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("The fiat family")
            }

            Repeater {
                model: [
                    { name: "fiat agenda", what: qsTr("let there be doing — a task list"), icon: "images/family/harbour-fiatagenda.png", url: "https://munkstolen.se" },
                    { name: "fiat margo", what: qsTr("let there be edge — keeps edges"), icon: "images/family/harbour-fiatmargo.png", url: "https://munkstolen.se" },
                    { name: "fiat glossa", what: qsTr("let there be tongue — a translator"), icon: "images/family/harbour-fiatglossa.png", url: "https://munkstolen.se" },
                    { name: "fiat vox", what: qsTr("let there be voice — a chromatic tuner"), icon: "images/family/harbour-fiatvox.png", url: "https://munkstolen.se" },
                    { name: "fiat pons", what: qsTr("let there be bridge — a native Qobuz client"), icon: "images/family/harbour-fiatpons.png", url: "https://munkstolen.se" },
                    { name: "fiat lux", what: qsTr("let there be light — a light meter for film"), icon: "images/family/harbour-fiatlux.png", url: "https://munkstolen.se" },
                    { name: "fiat cor", what: qsTr("let there be heart — a metronome"), icon: "images/family/harbour-fiatcor.png", url: "https://munkstolen.se" },
                    { name: "fiat passus", what: qsTr("let there be step — a step counter - Coming soon"), icon: "images/family/harbour-fiatpassus.png", url: "" },
                    { name: "fiat mos", what: qsTr("let there be habit — a habit tracker"), icon: "images/family/harbour-fiatmos.png", url: "https://munkstolen.se" },
                    { name: "fiat imago", what: qsTr("let there be image — a raw editor"), icon: "images/family/harbour-fiatimago.png", url: "https://munkstolen.se" },
                    { name: "fiat ratio", what: qsTr("let there be reckoning — a budget tool"), icon: "images/family/harbour-fiatratio.png", url: "https://munkstolen.se" },
                    { name: "fiat penus", what: qsTr("let there be provisions — this one"), icon: "images/family/harbour-fiatpenus.png", url: "" },
                    { name: "fiat tessera", what: qsTr("let there be token — a card wallet"), icon: "images/family/harbour-fiattessera.png", url: "https://munkstolen.se" }
                ]

                // A full-size icon in a row of its own height, rather than an
                // icon shrunk to the height of two lines of text. The icon is
                // the app's face; it should be readable.
                delegate: BackgroundItem {
                    width: content.width
                    height: Theme.itemSizeMedium
                    enabled: modelData.url !== ""
                    highlightedColor: FiatPenusTheme.highlightWash
                    onClicked: Qt.openUrlExternally(modelData.url)

                    Image {
                        id: familyIcon
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.itemSizeSmall
                        height: Theme.itemSizeSmall
                        sourceSize.width: Theme.itemSizeSmall
                        sourceSize.height: Theme.itemSizeSmall
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: Qt.resolvedUrl(modelData.icon)
                    }

                    Column {
                        anchors.left: familyIcon.right
                        anchors.leftMargin: Theme.paddingLarge
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: FiatPenusTheme.serif
                            color: modelData.url !== "" ? FiatPenusTheme.accent : FiatPenusTheme.primaryText
                            text: modelData.name
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: FiatPenusTheme.secondaryText
                            text: modelData.what
                        }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            // -- Version ---------------------------------------------------
            //
            // Last, because it is support and not identity. The number comes
            // from the rpm spec by way of qmake, so it is the one the package
            // was actually built with rather than one written down twice.

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Version")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeSmall
                color: FiatPenusTheme.primaryText
                text: typeof appVersion !== "undefined" ? appVersion : qsTr("unknown")
            }

            // -- Colophon --------------------------------------------------

            Item { width: 1; height: Theme.itemSizeExtraSmall }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatPenusTheme.innerBorder
            }

            Item { width: 1; height: Theme.paddingLarge }

            MunkstolenMark {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeMedium
                frame: "ring"
                color: FiatPenusTheme.makerMark
            }

            Item { width: 1; height: Theme.paddingSmall }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "munkstolen"
                font.pixelSize: Theme.fontSizeSmall
                font.family: FiatPenusTheme.serif
                font.italic: true
                color: FiatPenusTheme.makerMark
            }
        }

        VerticalScrollDecorator { }
    }
}
