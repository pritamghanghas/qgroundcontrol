#ifndef SENSORNOTIFICATION_H
#define SENSORNOTIFICATION_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QTimer>
#include <QUrl>
#include <QGeoCoordinate>
#include <QSettings>

//const QUrl url("http://localhost/notification.txt");
const QUrl url("http://www.proretailers.com/DroneEmail/dronemsg.jsp");
const int fetchInterval = 5000; //5secs

class SensorNotification : public QObject
{
    Q_OBJECT
public:
    explicit SensorNotification(QObject *parent = 0);

signals:
    void newFlyToCoord(const QGeoCoordinate& coord, double relAltitude);

public slots:

private slots:
    void onFinished();
    void onFetchTimerExpired();

private:
    QNetworkAccessManager *_nam;
    QTimer                 _fetchTimer;
    QSettings             *_settings;
};

#endif // SENSORNOTIFICATION_H
