#include "files.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QStandardPaths>
#include <QUrl>

Files::Files(QObject *parent)
    : QObject(parent)
{
}

QString Files::folder() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/pictures");
}

QString Files::localPath(const QString &fileUrl) const
{
    const QUrl url(fileUrl);
    const QString path = url.isLocalFile() ? url.toLocalFile() : fileUrl;
    const QFileInfo info(path);
    if (!info.isFile() || !info.isReadable())
        return QString();
    // Only what the phone can show: a JPEG beside a RAW file, yes; the DNG
    // itself has no decoder here and would hang on the board as a grey square.
    QImageReader reader(info.absoluteFilePath());
    if (!reader.canRead())
        return QString();
    return info.absoluteFilePath();
}

QString Files::documentPath(const QString &name) const
{
    // A bare file name only: nothing may climb out of Documents.
    if (name.isEmpty() || name.contains(QLatin1Char('/')) || name.startsWith(QLatin1Char('.')))
        return QString();
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    return dir.isEmpty() ? QString() : dir + QLatin1Char('/') + name;
}

bool Files::documentExists(const QString &name) const
{
    const QString path = documentPath(name);
    return !path.isEmpty() && QFileInfo(path).isFile();
}

QString Files::readDocument(const QString &name) const
{
    QFile file(documentPath(name));
    if (!file.open(QIODevice::ReadOnly))
        return QString();
    return QString::fromUtf8(file.readAll());
}

bool Files::retireDocument(const QString &name) const
{
    const QString path = documentPath(name);
    if (path.isEmpty() || !QFileInfo(path).isFile())
        return false;
    QString target = path;
    if (target.endsWith(QLatin1String(".json")))
        target.chop(5);
    target += QLatin1String(".imported.json");
    QFile::remove(target);
    return QFile::rename(path, target);
}

bool Files::forget(const QString &path) const
{
    const QString clean = QDir::cleanPath(path);
    if (!clean.startsWith(folder() + QLatin1Char('/')))
        return false;
    return QFile::remove(clean);
}
