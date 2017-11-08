#ifndef PIDISCOVERER_H
#define PIDISCOVERER_H

#include <QObject>
#include <QUrl>
#include <QElapsedTimer>
#include <QtNetwork/QUdpSocket>

class PiNode
{
public:
    PiNode();
    bool isValid() const { return !addressString.isEmpty(); }
    bool isAlive() const { return beaconTimer.isValid() && beaconTimer.elapsed() < 5*latency; }
    QUrl mjpegServerUrl() const { return QUrl("http://"+ addressString + ":5002/cam.mjpg"); }
    bool operator ==(const PiNode &node) const;

    enum NodeCaps {
        NONE        = 0,
        PICAM       = 1,
        UVC         = 1 << 1,
        LEPTON      = 1 << 2,
        SEEK        = 1 << 3,
        MAVTCP      = 1 << 4,
        MAVUDP      = 1 << 5,
        AP          = 1 << 6,
        SIKRADIO    = 1 << 7,
    };

    int                     caps;
    int                     capsRunning;
    int                     targetStreamingPort;
    int                     beaconInterval;
    int                     heartBeatCount;
    quint32                 lastLanSeqNum;
    QHostAddress            address;
    quint32                 latency;
    QString                 addressString,
                            uniqueId;
    QVariantMap             hostAPDConf;
    QElapsedTimer           beaconTimer;
};

#define PiNodeList QList<PiNode>

class PiDiscoverer : public QObject
{
    Q_OBJECT
public:
    explicit PiDiscoverer(QObject *parent = 0);
    void startDiscovery();
    PiNodeList discoveredNodes() const;
    void setDiscoveredNodes(const PiNodeList nodes);

Q_SIGNALS:
    void nodeDiscovered(const PiNode &node);
    void nodeUpdated(const PiNode &node);

private Q_SLOTS:
    void datagramReceived();
    void onNodeDiscovered(const PiNode &node);

private:
    void updateNode(const PiNode &node);
    QUdpSocket m_socket;
    PiNodeList m_discoveredNodes;
};

#endif // PIDISCOVERER_H
