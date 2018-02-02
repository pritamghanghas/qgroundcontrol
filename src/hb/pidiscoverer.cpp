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
        qDebug() << "something wrong with the heartbeat, we have less than 5 tokens";
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
        Q_EMIT nodeDiscovered(m_discoveredNodes[index]);
        onNodeDiscovered(m_discoveredNodes[index]);
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
    auto expectedSeqNum = m_discoveredNodes[index].lastLanSeqNum+1;
    static auto unordered = 0;
    if (expectedSeqNum != node.lastLanSeqNum) {
//        qDebug() << "lost a packet or unordered packets coming" << "expected: " << expectedSeqNum << " last seq no: " << node.lastLanSeqNum;
        if (expectedSeqNum > node.lastLanSeqNum) {
//            qDebug() << "got late heartbeat " << "expected: " << expectedSeqNum << " last seq no: " << node.lastLanSeqNum;
        }
        m_discoveredNodes[index].lastLanSeqNum = node.lastLanSeqNum;
//        m_discoveredNodes[index].beaconTimer.restart();
        unordered++;
        return;
    }

//    qDebug() << "unordered lost till now" << unordered;
    auto newLatency = m_discoveredNodes[index].beaconTimer.restart() - node.beaconInterval*(unordered+1);
//    qDebug() << "calculated latency" << newLatency;
    unordered = 0;

    auto oldLatency =  m_discoveredNodes[index].latency;
    newLatency = newLatency < 0 ? 0 : newLatency;
    newLatency = newLatency ? newLatency : oldLatency;

//    qDebug() << "adjusted new latency" << newLatency << " beacon interval " << node.beaconInterval;


//    m_discoveredNodes[index].latency = oldLatency ? (0.7*oldLatency + 0.3*newLatency) : newLatency;
    m_discoveredNodes[index].latency = 1000;
    m_discoveredNodes[index].lastLanSeqNum = node.lastLanSeqNum;
    m_discoveredNodes[index].heartBeatCount++;

    if (m_discoveredNodes[index].heartBeatCount == 30) { // we will use higher count and latency determination here later.
//    if (m_discoveredNodes[index].heartBeatCount == 1) {
//        Q_EMIT nodeDiscovered(m_discoveredNodes[index]);
//        onNodeDiscovered(m_discoveredNodes[index]);
        // not waiting for latency number before claiming we have one.
        // we are not uing latency anyway
    }

//    debugNode(m_discoveredNodes[index]);
    Q_EMIT nodeUpdated(m_discoveredNodes[index]);
}

void PiDiscoverer::debugNode(const PiNode &node)
{
    qDebug() << "Debug information for node";
    qDebug() << "id : " << node.uniqueId;
    qDebug() << "caps : " << node.caps;
    qDebug() << "latency: " << node.latency;
    qDebug() << "seqNum : " << node.lastLanSeqNum;
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
