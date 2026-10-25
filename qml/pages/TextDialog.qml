import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

// One line of text: a folder's name, a photo's caption.
Dialog {
    id: dialog

    property string title: ""
    property string label: ""
    property string value: ""
    property bool allowEmpty: false

    canAccept: allowEmpty || field.text.trim() !== ""

    onAccepted: value = field.text.trim()

    function paint() { FiatPenusTheme.applyPalette(dialog) }
    Component.onCompleted: {
        paint()
        field.forceActiveFocus()
    }

    FiatBackground { }

    Column {
        width: parent.width
        spacing: Theme.paddingSmall

        DialogHead {
            owner: dialog
            title: dialog.title
        }
        TextField {
            id: field
            width: parent.width
            text: dialog.value
            label: dialog.label
            placeholderText: dialog.label
            // Without it the keyboard holds back the last word until a space.
            inputMethodHints: Qt.ImhNoPredictiveText
            EnterKey.enabled: dialog.canAccept
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: dialog.accept()
        }
    }
}
