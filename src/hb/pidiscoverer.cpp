#include "pidiscoverer.h"

#define PIDISCOVERER_BROADCAST_PORT 31311
#define STREAMING_PORT_LOWEST 5003
PiNode::PiNode()
{
    caps        = PiNode::NONE;
    capsRunning = PiNode::NONE;

    targetStreamingPort = STREAMING_PORT_LOWEST;
    beaconInterval      = 0;
    lastLanSeqNum       = 0;
    latency             = 0;
}

bool PiNode::operator ==(const PiNode &node) const
{
    return (this->address == node.address);
}

PiDiscoverer::PiDiscoverer(QObject *parent) : QObject(parent)
{
}

void PiDiscoverer::startDiscovery()
{
    static bool started = false;
    if (!started) {
        m_socket.bind(QHostAddress::Any, PIDISCOVERER_BROADCAST_PORT);
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

    // not our packet
    if (!datagram.startsWith("raspberry")) {
        return;
    }

    // process packet
    QString beacon = QString(datagram);
    QStringList tokens = beacon.split(' ');

    if (tokens.count() < 5) {
        qDebug() << "something wrong with the heartbeat, we have only less than 5 tokens";
        return;
    }

    PiNode node;

    // TODO: some optimization opportunity, we don't need to process the whole node
    // as if it is not a new node, we need very few fields
    node.uniqueId            = tokens.at(1);
    node.caps                = QString(tokens.at(2)).toInt();
    node.beaconInterval      = QString(tokens.at(3)).toInt();
    node.heartBeatCount      = 1;
    node.address             = addr;
    node.addressString       = addr.toString().split(":").last();
    node.lastLanSeqNum       = QString(tokens.at(4)).toUInt();
    node.targetStreamingPort = STREAMING_PORT_LOWEST + m_discoveredNodes.count();
    node.beaconTimer.start();

    if (!m_discoveredNodes.contains(node)) {
        qDebug() << "new unique node adding";
        m_discoveredNodes << node;
    } else {
        updateNode(node);
    }
}

// this is not the first heartbeat for this node.
// we need to update the latency numbers averaged
// and publish it as  discovered if more than 3 heartbeats
// have been receieved for this node
void PiDiscoverer::updateNode(const PiNode &node)
{
    int index = m_discoveredNodes.indexOf(node);
    int expectedSeqNum = m_discoveredNodes[index].lastLanSeqNum+1;
    if (expectedSeqNum != node.lastLanSeqNum) {
        qDebug() << "lost a packet or unordered packets coming" << "expected: " << expectedSeqNum << " last seq no: " << node.lastLanSeqNum;
        return;
    }
    if (expectedSeqNum > node.lastLanSeqNum) {
        qDebug() << "got late heartbeat " << "expected: " << expectedSeqNum << " last seq no: " << node.lastLanSeqNum;
        return;
    }

    auto newLatency = m_discoveredNodes[index].beaconTimer.restart() - node.beaconInterval;

    auto oldLatency =  m_discoveredNodes[index].latency;

    m_discoveredNodes[index].latency = 0.8*oldLatency + 0.2*newLatency;
    m_discoveredNodes[index].lastLanSeqNum = node.lastLanSeqNum;
    m_discoveredNodes[index].heartBeatCount++;

    if (m_discoveredNodes[index].heartBeatCount == 3) {
        Q_EMIT nodeDiscovered(m_discoveredNodes[index]);
        onNodeDiscovered(m_discoveredNodes[index]);
    }
    nodeUpdated(m_discoveredNodes[index]);
}

PiNodeList PiDiscoverer::discoveredNodes() const
{
    return m_discoveredNodes;
}

void PiDiscoverer::setDiscoveredNodes(const QList<PiNode> nodes)
{
    m_discoveredNodes = nodes;
}

void PiDiscoverer::onNodeDiscovered(const PiNode &node)
{

}
