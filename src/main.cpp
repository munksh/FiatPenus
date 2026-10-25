#include <QtQuick>

#include <sailfishapp.h>

#include "account.h"
#include "api.h"
#include "authnam.h"
#include "files.h"

#ifndef APP_VERSION
#define APP_VERSION "0.0.0-dev"
#endif

// Exported: the launcher's booster calls main() from outside, and Harbour's
// validator refuses a binary that hides it.
Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName(QStringLiteral("se.munkstolen"));
    app->setApplicationName(QStringLiteral("harbour-fiatpenus"));
    app->setApplicationVersion(QString::fromUtf8(APP_VERSION));

    Account account;
    Api api;
    Files files;
    QObject::connect(&account, &Account::signedOut, &api, &Api::clearCache);

    AuthNamFactory namFactory;
    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->engine()->setNetworkAccessManagerFactory(&namFactory);
    api.setEngine(view->engine());

    view->rootContext()->setContextProperty(QStringLiteral("account"), &account);
    view->rootContext()->setContextProperty(QStringLiteral("api"), &api);
    view->rootContext()->setContextProperty(QStringLiteral("files"), &files);
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"), QString::fromUtf8(APP_VERSION));
    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
