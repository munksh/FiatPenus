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

bool Files::forget(const QString &path) const
{
    const QString clean = QDir::cleanPath(path);
    if (!clean.startsWith(folder() + QLatin1Char('/')))
        return false;
    return QFile::remove(clean);
}
