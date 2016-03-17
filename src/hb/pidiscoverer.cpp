#include "pidiscoverer.h"

#define PIDISCOVERER_BROADCAST_PORT 31311
#define STREAMING_PORT_LOWEST 5003
PiNode::PiNode()
{
    caps        = PiNode::None;
    capsRunning = PiNode::None;

    targetStreamingPort = STREAMING_PORT_LOWEST;
}

bool PiNode::operator ==(const PiNode &node) const
{
    return (this->addressString == node.addressString);
}

PiDiscoverer::PiDiscoverer(QObject *parent) : QObject(parent)
{
}

void PiDiscoverer::startDiscovery()
{
    static bool started = false;
    if (!started) {
        m_socket.bind(PIDISCOVERER_BROADCAST_PORT);
        connect(&m_socket, SIGNAL(readyRead()), SLOT(datagramReceived()));
    }
}

void PiDiscoverer::datagramReceived()
{
    qint64 datagramSize = m_socket.pendingDatagramSize();
    QByteArray datagram;
    datagram.resize(datagramSize);
    QHostAddress addr;
    m_socket.readDatagram(datagram.data(), datagramSize, &addr);

//    qDebug() << "data received " << datagram.data();
    PiNode node;
    if (datagram.startsWith("raspberry")) {
        if (datagram.contains("picam")) {
            node.caps |= PiNode::PiCam;
        }

        if (datagram.contains("thermal")) {
            node.caps |= PiNode::Thermal;
        }

        if (datagram.contains("mavproxy")) {
            node.caps |= PiNode::MAVProxy;
        }
        node.targetStreamingPort = STREAMING_PORT_LOWEST + m_discoveredNodes.count();
        node.address = addr;
        node.addressString = addr.toString().split(":").last();
        onNodeDiscovered(node);
    }
}

PiNodeList PiDiscoverer::discoveredNodes() const
{
    return m_discoveredNodes;
}

void PiDiscoverer::onNodeDiscovered(const PiNode &node)
{
//    qDebug() << "node discovered " << node.addressString;
    if (!m_discoveredNodes.contains(node)) {
        qDebug() << "new unique node adding" << node.addressString;
        m_discoveredNodes << node;
        Q_EMIT nodeDiscovered(node);
    }
}
