/*
 * The Fiat colours background: a vertical gradient from backgroundHigh to
 * backgroundLow, painted by every page that can be seen.
 *
 * Under an ambience there is no background rectangle at all -- the wallpaper
 * IS the background. An unconditional background is how you cancel someone's
 * ambience without meaning to.
 */

import QtQuick 2.0
import ".."

Rectangle {
    anchors.fill: parent
    visible: !FiatPenusTheme.ambient
    gradient: Gradient {
        GradientStop { position: 0.0; color: FiatPenusTheme.backgroundHigh }
        GradientStop { position: 1.0; color: FiatPenusTheme.backgroundLow }
    }
}
