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
        NONE        = 0x00,
        PICAM       = 0x01,
        UVC         = 0x03,
        LEPTON      = 0x07,
        SEEK        = 0x0F,
        MAVTCP      = 0x1f,
        MAVUDP      = 0x3F,
        AP          = 0x7F,
        SIKRADIO    = 0xFF,
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
