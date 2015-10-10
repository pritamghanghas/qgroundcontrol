#ifndef PIDISCOVERER_H
#define PIDISCOVERER_H

#include <QObject>
#include <QUrl>
#include <QtNetwork/QUdpSocket>

class PiNode
{
public:
    PiNode();
    bool isValid() const { return !addressString.isEmpty(); }
    QUrl mjpegServerUrl() const { return QUrl("http://"+ addressString + ":5002/cam.mjpg"); }
    bool operator ==(const PiNode &node) const;

    enum NodeCaps {
        None        = 0x00,
        PiCam       = 0x01,
        Thermal     = 0x10,
        MAVProxy    = 0x100
    };

    int caps;
    int capsRunning;
    int targetStreamingPort;
    QHostAddress address;
    QString addressString;
};

#define PiNodeList QList<PiNode>

class PiDiscoverer : public QObject
{
    Q_OBJECT
public:
    explicit PiDiscoverer(QObject *parent = 0);
    void startDiscovery();
    PiNodeList discoveredNodes() const;

Q_SIGNALS:
    void nodeDiscovered(const PiNode &node);

private Q_SLOTS:
    void datagramReceived();
    void onNodeDiscovered(const PiNode &node);

private:
    QUdpSocket m_socket;
    PiNodeList m_discoveredNodes;
};

#endif // PIDISCOVERER_H
