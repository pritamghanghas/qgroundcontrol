#include "sensornotification.h"
#include <QNetworkReply>
#include <QNetworkRequest>

SensorNotification::SensorNotification(QObject *parent) : QObject(parent)
{
    _nam = new QNetworkAccessManager(this);
    _settings = new QSettings(this);
    _fetchTimer.setInterval(fetchInterval);
    connect(&_fetchTimer, &QTimer::timeout, this, &SensorNotification::onFetchTimerExpired);
    _fetchTimer.start();
}


void SensorNotification::onFetchTimerExpired()
{
    _settings->beginGroup("HB");
    bool scountEnabled = _settings->value("scoutMode", false).toBool();
    _settings->endGroup();

    if (!scountEnabled) {
//        qDebug("fence breach scout mode not enabled.. doing nothing");
        return;
    }
    qDebug("scout mode is enabled polling server");
    QNetworkReply * reply = _nam->get(QNetworkRequest(url));
    connect(reply, &QNetworkReply::finished, this, &SensorNotification::onFinished);
    connect(reply, &QNetworkReply::finished, reply, &QNetworkReply::deleteLater);
}

void SensorNotification::onFinished()
{
    QNetworkReply *reply = dynamic_cast<QNetworkReply*>(sender());
    if(!reply) {
        qDebug() << "sender object is not reply, we don't care...";
        return;
    }
    if (reply->error() != QNetworkReply::NoError) {
        qDebug() << "error in network reply from fence trip api" << reply->error();
        return;
    }

    QString notificationText = reply->readAll();
    if (notificationText.contains("body")) {
        notificationText = notificationText.split("<body>").last();
        notificationText = notificationText.split("</body>").first();
        notificationText = notificationText.simplified();
        qDebug() << "after cleaning up html " << notificationText;
    }


    qDebug() << "notification text " << notificationText;
    QStringList flytoData = notificationText.split("#");
    if(flytoData.size() !=4) {
        qDebug() << "there should be exactly 4 fragments in the subject of agreed msg. this has "
                 << flytoData.size();
        return;
    }
    QString date = flytoData.at(1);
    qDebug() << "date string " << date;
    QDateTime dTime = QDateTime::fromString(date, "MMM dd, yyyy h:mm:s.z AP");
    if(!dTime.isValid()) {
        qDebug() << "faild to parse date time";
    }
    qDebug() << "extracted date time " << dTime
             << " current date time " << QDateTime::currentDateTime();
    if (dTime.secsTo(QDateTime::currentDateTime()) > 120) {
        qDebug() << "incoming message is older than 2min. Discarding....";
        return;
    }

    // lets get to work with actual data now
    QString lat = flytoData.at(2);
    QString lon = flytoData.at(3);
    qDebug() << "extracted lat: " << lat << " lon: " << lon;
    QGeoCoordinate coord(lat.toDouble(), lon.toDouble());
    qDebug() << "qt's representation of lat lon" << coord;

    _settings->beginGroup("HB");
    double flyToAltitude = _settings->value("scoutAltitude", 40).toDouble();
    _settings->endGroup();
    emit newFlyToCoord(coord, flyToAltitude);
}
