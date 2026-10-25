# fiat penus — a Pantry client for Nextcloud
TARGET = harbour-fiatpenus

# Version: one source of truth, the spec. The spec passes it to qmake
# (%qmake5 APP_VERSION=%{version}); a plain qmake run in Qt Creator falls back.
isEmpty(APP_VERSION) {
    APP_VERSION = 0.0.0-dev
}
DEFINES += APP_VERSION=\\\"$$APP_VERSION\\\"

CONFIG += sailfishapp
QT += network

SOURCES += \
    src/main.cpp \
    src/account.cpp \
    src/api.cpp \
    src/authnam.cpp \
    src/credentials.cpp \
    src/files.cpp

HEADERS += \
    src/account.h \
    src/api.h \
    src/authnam.h \
    src/credentials.h \
    src/files.h

REQUIRED_FILES = \
    $${TARGET}.desktop \
    qml/$${TARGET}.qml \
    qml/qmldir \
    qml/FiatPenusTheme.qml \
    qml/js/markdown.js \
    qml/js/util.js \
    qml/js/storage.js \
    qml/js/shelf.js \
    qml/components/PageHead.qml \
    qml/components/DialogHead.qml \
    qml/components/SectionLabel.qml \
    qml/components/EmptyNote.qml \
    qml/components/MunkstolenMark.qml \
    qml/components/WordChoice.qml \
    qml/components/LinkText.qml \
    qml/components/FiatButton.qml \
    qml/components/FiatBackground.qml \
    qml/components/FaceCard.qml \
    qml/components/Ring.qml \
    qml/components/Pill.qml \
    qml/components/ModeHead.qml \
    qml/components/HouseHead.qml \
    qml/components/FrontMenu.qml \
    qml/components/ShareNote.qml \
    qml/pages/MainPage.qml \
    qml/pages/images/family/harbour-fiatpenus.png \
    qml/pages/images/family/harbour-fiatagenda.png \
    qml/pages/images/family/harbour-fiatcor.png \
    qml/pages/images/family/harbour-fiatglossa.png \
    qml/pages/images/family/harbour-fiatimago.png \
    qml/pages/images/family/harbour-fiatlux.png \
    qml/pages/images/family/harbour-fiatmargo.png \
    qml/pages/images/family/harbour-fiatmos.png \
    qml/pages/images/family/harbour-fiatpons.png \
    qml/pages/images/family/harbour-fiatpassus.png \
    qml/pages/images/family/harbour-fiatratio.png \
    qml/pages/images/family/harbour-fiatvox.png \
    LICENSE
for(f, REQUIRED_FILES) {
    !exists($$PWD/$$f): error("Missing $$f -- expected it at $$PWD/$$f")
}

DISTFILES += \
    qml/harbour-fiatpenus.qml \
    qml/FiatPenusTheme.qml \
    qml/qmldir \
    qml/cover/*.qml \
    qml/pages/*.qml \
    qml/components/*.qml \
    qml/js/*.js \
    qml/pages/images/family/*.png \
    rpm/harbour-fiatpenus.spec \
    harbour-fiatpenus.desktop \
    README.md

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

licensefile.files = $$PWD/LICENSE
# Harbour installs nothing outside /usr/share/$${TARGET}, so the licence
# goes there and not to /usr/share/licenses.
licensefile.path = /usr/share/$${TARGET}
INSTALLS += licensefile
