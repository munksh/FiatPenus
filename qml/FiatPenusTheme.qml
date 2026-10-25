pragma Singleton
import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

QtObject {
    id: t

    property ConfigurationValue ambientConfig: ConfigurationValue {
        key: "/apps/harbour-fiatpenus/ambient"
        defaultValue: true
    }
    readonly property bool ambient: ambientConfig.value === true || ambientConfig.value === "true"
    function setAmbient(on) { ambientConfig.value = on }

    readonly property bool dark: ambient ? (Theme.colorScheme === Theme.LightOnDark) : false
    readonly property string serif: "Georgia"

    // ---- the notch ----
    function cutoutHeight() {
        if (typeof Screen === "undefined" || Screen === null) return -1
        var c = Screen.topCutout
        if (c === undefined || c === null) return -1
        if (typeof c === "number") return c
        if (c.height !== undefined) return c.height
        return -1
    }
    readonly property real headerTopInsetFallback: Theme.paddingLarge * 1.5
    readonly property real headerTopInset: {
        var c = cutoutHeight()
        return c >= 0 ? c + Theme.paddingMedium : headerTopInsetFallback
    }
    // Written down, not derived. Two derivations walked the wordmark up the screen.
    readonly property real statusRowCenter: Theme.itemSizeLarge / 2

    // ---- text and accent ----
    readonly property color primaryText:   ambient ? Theme.primaryColor   : "#1A1A1A"
    readonly property color secondaryText: ambient ? Theme.secondaryColor : Qt.rgba(0.10, 0.10, 0.10, 0.72)
    // Old gold, 4.7:1 on the paper. The icon's gold (#E0AE4A) is lighter and
    // cannot carry small text; this is the same warmth at reading strength.
    readonly property color accent:        ambient ? Theme.highlightColor : "#926000"

    function mixColor(a, b, f) {
        return Qt.rgba(a.r * (1 - f) + b.r * f, a.g * (1 - f) + b.g * f, a.b * (1 - f) + b.b * f, 1.0)
    }
    // For Silica chrome that paints large areas in palette.highlightColor.
    readonly property color chromeAccent: mixColor(accent, primaryText, 0.35)

    // ---- paper and surfaces ----
    readonly property color backgroundHigh: "#F2EFE8"
    readonly property color backgroundLow:  "#D8D2C6"
    readonly property color card: ambient
        ? (dark ? Qt.rgba(0.08, 0.08, 0.08, 1.0) : Qt.rgba(0.96, 0.96, 0.96, 1.0))
        : "#F5F5F5"
    readonly property color surface: card
    readonly property color cardBorder:   Theme.rgba(primaryText, 0.45)
    readonly property color innerBorder:  Theme.rgba(primaryText, 0.22)
    readonly property color recessFill:   Theme.rgba(primaryText, 0.05)
    readonly property color recessBorder: Theme.rgba(primaryText, 0.16)
    readonly property real cardRadius: Theme.paddingLarge * 2
    readonly property int cardBorderWidth: 2

    readonly property color pillFill:         Theme.rgba(primaryText, 0.15)
    readonly property color pillBorder:       Theme.rgba(primaryText, 0.55)
    readonly property color pillFillActive:   Theme.rgba(accent, 0.15)
    readonly property color pillBorderActive: Theme.rgba(accent, 0.45)
    // Choices that move you around the front page: the three sides and the
    // households. Choices of a value stay at fontSizeSmall.
    readonly property int navFontSize: Theme.fontSizeMedium
    readonly property color hairline: Theme.rgba(primaryText, 0.12)
    readonly property color markIdle: Theme.rgba(primaryText, 0.30)

    readonly property color dotIdle: Theme.rgba(primaryText, 0.22)
    readonly property color highlightWash: Theme.rgba(accent, 0.15)
    readonly property color wash: Theme.rgba(accent, 0.07)

    // A function, not a chain of readonly bindings: the chained version came
    // out undefined on the device, and an undefined colour renders black.
    function markOn(c) {
        if (c === undefined || c === null) return "#F5F5F5"
        return (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) > 0.55 ? "#1A1A1A" : "#F5F5F5"
    }
    readonly property color onAccent: markOn(accent)

    // Munkstolen's colour, not the app's: fixed, like the launcher icon.
    readonly property color makerMark: "#7E7566"

    // ---- meaning, never decoration ----
    // The server refused, or could not be reached for a change.
    // Lighter on a dark ambience than the family's #A0403A, which is 2.7:1
    // there; #F08A80 is 7.2:1.
    readonly property color wrong: dark ? "#F08A80" : "#8A2B25"

    readonly property real markSize: Theme.itemSizeSmall * 0.6

    // Canvas wants CSS colours; a QML color with alpha prints as #AARRGGBB.
    function css(c) {
        var q = Qt.lighter(c, 1.0)
        return "rgba(" + Math.round(q.r * 255) + "," + Math.round(q.g * 255) + ","
                + Math.round(q.b * 255) + "," + q.a + ")"
    }

    function applyPalette(item) {
        if (item === null || item === undefined) return
        var p = item.palette
        if (p === undefined || p === null) return
        try { p.colorScheme = ambient ? Theme.colorScheme : Theme.DarkOnLight } catch (e) { }
        try { p.primaryColor = primaryText } catch (e) { }
        try { p.secondaryColor = secondaryText } catch (e) { }
        try { p.highlightColor = chromeAccent } catch (e) { }
        try { p.secondaryHighlightColor = Theme.rgba(chromeAccent, 0.6) } catch (e) { }
        try { p.highlightBackgroundColor = Theme.rgba(primaryText, 0.12) } catch (e) { }
        try { p.errorColor = wrong } catch (e) { }
        try { p.highlightDimmerColor = ambient ? Theme.highlightDimmerColor : backgroundLow } catch (e) { }
        try { p.overlayBackgroundColor = ambient ? Theme.overlayBackgroundColor : backgroundHigh } catch (e) { }
    }

    // ---- cover geometry, identical in every Fiat app ----
    readonly property real coverWordmarkTop:         Theme.paddingLarge
    readonly property real coverSideMargin:          Theme.paddingLarge
    readonly property real coverFigureFraction:      0.28
    readonly property real coverFigureFractionShape: 0.20
    readonly property int  coverFigureSize:          Theme.fontSizeHuge
    readonly property real coverArtFraction:         0.5
}
