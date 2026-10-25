#ifndef API_H
#define API_H

#include <QHash>
#include <QJSValue>
#include <QObject>
#include <QString>

class QJSEngine;
class QNetworkAccessManager;
class QNetworkReply;

// The Pantry API for QML: every call is relative to
// /ocs/v2.php/apps/pantry/api and answers a callback
//     function (ok, data, status, message)
// with the OCS payload already unwrapped. GET answers are kept on disk, so a
// page can show the last known state before the network has answered.
class Api : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(bool offline READ offline NOTIFY offlineChanged)

    // What the cover shows: the list last looked at.
    Q_PROPERTY(QString coverTitle READ coverTitle WRITE setCoverTitle NOTIFY coverChanged)
    Q_PROPERTY(int coverOpen READ coverOpen WRITE setCoverOpen NOTIFY coverChanged)
    Q_PROPERTY(int coverDone READ coverDone WRITE setCoverDone NOTIFY coverChanged)

public:
    explicit Api(QObject *parent = nullptr);

    void setEngine(QJSEngine *engine) { m_engine = engine; }

    int busy() const { return m_busy; }
    QString error() const { return m_error; }
    bool offline() const { return m_offline; }

    QString coverTitle() const { return m_coverTitle; }
    int coverOpen() const { return m_coverOpen; }
    int coverDone() const { return m_coverDone; }
    void setCoverTitle(const QString &title);
    void setCoverOpen(int open);
    void setCoverDone(int done);

    Q_INVOKABLE void get(const QString &path, const QJSValue &query, const QJSValue &callback);
    Q_INVOKABLE void send(const QString &method, const QString &path, const QJSValue &body,
                          const QJSValue &callback);
    Q_INVOKABLE void upload(const QString &path, const QString &fileUrl, const QJSValue &fields,
                            const QJSValue &callback);

    Q_INVOKABLE QJSValue cached(const QString &path, const QJSValue &query) const;
    Q_INVOKABLE QString imageUrl(const QString &path, const QJSValue &query) const;
    Q_INVOKABLE void dismissError();

public slots:
    void clearCache();

signals:
    void busyChanged();
    void errorChanged();
    void offlineChanged();
    void coverChanged();
    void unauthorized();

private:
    QString urlFor(const QString &path, const QJSValue &query) const;
    QString cacheFile(const QString &url) const;
    void track(QNetworkReply *reply, const QJSValue &callback, bool cacheIt, int timeoutMs);
    void finished(QNetworkReply *reply);
    void setError(const QString &error);
    void setOffline(bool offline);
    void setBusy(int busy);

    QJSEngine *m_engine = nullptr;
    QNetworkAccessManager *m_nam;
    QHash<QNetworkReply *, QJSValue> m_callbacks;
    QHash<QNetworkReply *, QString> m_cacheKeys;

    int m_busy = 0;
    QString m_error;
    bool m_offline = false;

    QString m_coverTitle;
    int m_coverOpen = -1;
    int m_coverDone = 0;
};

#endif
