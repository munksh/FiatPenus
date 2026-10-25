#ifndef FILES_H
#define FILES_H

#include <QObject>
#include <QString>

// The pictures of the phone's own household. A picture chosen from the
// gallery is not copied: the household keeps the original's path, so there is
// one file, the one in Gallery. Deleting it there takes it off the board too.
class Files : public QObject
{
    Q_OBJECT

public:
    explicit Files(QObject *parent = nullptr);

    // The path of the file a picker returned (a file:// URL or a path), or ""
    // when there is no picture there that the app may read and show.
    Q_INVOKABLE QString localPath(const QString &fileUrl) const;
    // Removes a picture an earlier test build copied into the app's own
    // folder. Anything outside that folder -- the originals in Gallery -- is
    // never touched.
    Q_INVOKABLE bool forget(const QString &path) const;

private:
    QString folder() const;
};

#endif
