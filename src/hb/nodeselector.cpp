#include "nodeselector.h"
#include <QNetworkInterface>
#include <QNetworkRequest>
#include <QNetworkReply>

static const QString PLAY_CMD("udpsrc port=$PORT ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264");
static const QString PICAM_REMOTE_CMD("raspivid -t 0 $OPT_STRING -o - | gst-launch-1.0 fdsrc ! h264parse ! rtph264pay config-interval=1 pt=96 ! udpsink host=$CLIENT_IP port=$UDP_PORT");
static const QString PICAM_REMOTE_CMD_RECORDING("raspivid -t 0 $OPT_STRING -o - | gst-launch-1.0 fdsrc ! tee name=t t. ! queue ! filesink location=/home/pi/media/videos/$TIMESTAMP.h264 t. ! queue ! h264parse ! rtph264pay config-interval=1 pt=96 ! udpsink host=$CLIENT_IP port=$UDP_PORT");

//static const QString MAVPROXY_REMOTE_CMD("screen -S MAVPROXY /usr/local/bin/mavproxy.py --master=127.0.0.1:1440 --baudrate 57600 --out $CLIENT_IP:14550 --aircraft MyCopter");
static const QString MAVPROXY_REMOTE_CMD("/home/pi/ardupilot/bin/start_ardupilot.sh $CLIENT_IP");
// FIXME:: Find a way to fix this with respect to wired
//static const QString MAVPROXY_REMOTE_CMD("/home/pi/bin/mavproxy_wrapper.sh $CLIENT_IP");

NodeSelector* NodeSelector::instance(QNetworkAccessManager *nam)
{
    static NodeSelector nodeSelector(nam);
    return &nodeSelector;
}

NodeSelector::NodeSelector(QNetworkAccessManager *nam, QObject *parent) :
    QObject(parent),
    m_currentIndex(0),
    m_hasVideo(false)
{
    // use supplied QNAM, otherwise create your own
    if (nam) {
        if(m_nam) {
           m_nam->deleteLater();
        }
        m_nam = nam;
    } else {
        if(!m_nam) {
            m_nam = new QNetworkAccessManager(this);
        }
    }
    Q_ASSERT(m_nam);

    m_discoverer = new PiDiscoverer(this);
    connect(m_discoverer, &PiDiscoverer::nodeDiscovered,
            this, &NodeSelector::onNewNodeDiscovered);
    m_discoverer->startDiscovery();
}

NodeSelector::~NodeSelector()
{
    PiNodeList nodes = m_discoverer->discoveredNodes();

    // terminate all nodes
    Q_FOREACH(const PiNode &node, nodes) {
            terminatePicam(node);
            terminateThermal(node);
            terminateMavProxy(node);
        }
}

void NodeSelector::terminatePicam(const PiNode &node)
{
    if (node.caps & PiNode::PICAM) {
        qDebug() << "termiante picam at node" << node.addressString;
        QUrl terminateUrl("http://" + node.addressString + ":8080/picam/?command=terminate");
        sendRequest(terminateUrl);
    }
}

void NodeSelector::hostapdget()
{
    PiNode node = currentNode();
    if(!node.isValid()) {
        return;
    }

    if (!node.hostAPDConf.isEmpty()) {
        return;
    }

    QString mavcmd = "http://" + node.addressString + ":8080/hostapdget";
    mavcmd.replace("$CLIENT_IP", deviceAddress(node));
    qDebug() << "mav command " << mavcmd;
    QVariantMap map;
    map.insert("requestFor", PiNode::AP);
    map.insert("nodeIndex", m_currentIndex);
    sendRequest(mavcmd, map);
}

void NodeSelector::terminateThermal(const PiNode &node)
{
    if (node.caps & PiNode::LEPTON) {
        qDebug() << "termiante thermal at node" << node.addressString;
        QUrl terminateUrl = QUrl("http://" + node.addressString + ":8080/thermalcam/?command=terminate");
        sendRequest(terminateUrl);
    }
}

void NodeSelector::shutdownAll()
{
    PiNodeList nodes = m_discoverer->discoveredNodes();
    Q_FOREACH(const PiNode &node, nodes) {
        QUrl shutdownUrl = QUrl("http://" + node.addressString + ":8080/os_command/?command=sudo halt");
        qDebug() << "shutting down pi node" << node.addressString;
        sendRequest(shutdownUrl);
    }
}

void NodeSelector::restartAll()
{
    PiNodeList nodes = m_discoverer->discoveredNodes();
    Q_FOREACH(const PiNode &node, nodes) {
        QUrl shutdownUrl = QUrl("http://" + node.addressString + ":8080/os_command/?command=sudo reboot");
        qDebug() << "rebooting down pi node" << node.addressString;
        sendRequest(shutdownUrl);
    }
}

void NodeSelector::terminateMavProxy(const PiNode &node)
{
    if (node.caps & PiNode::MAVUDP) {
        qDebug() << "terminate mavproxy at node" << node.addressString;
        QUrl terminateUrl = QUrl("http://" + node.addressString + ":8080/mavproxy/?command=screen -X -S MAVPROXY quit");
        sendRequest(terminateUrl);
    }
}

void NodeSelector::selectNext()
{
    PiNodeList nodes = m_discoverer->discoveredNodes();

    if (!nodes.size()) {
        qDebug() << __FUNCTION__ << "nodes are empty";
        return;
    }

    m_currentIndex = (m_currentIndex+1)%nodes.size();
}

void NodeSelector::selectPrevious()
{
    PiNodeList nodes = m_discoverer->discoveredNodes();

    if (!nodes.size()) {
        return;
    }

    m_currentIndex = m_currentIndex-1 < 0 ? nodes.size()-1 : m_currentIndex;
}

PiNode NodeSelector::currentNode() const
{
    PiNodeList nodes = m_discoverer->discoveredNodes();
    if (nodes.isEmpty()) {
        return PiNode();
    }
    return nodes.at(m_currentIndex);
}

QVariantMap NodeSelector::currentHostAPDConf() const
{
    return currentNode().hostAPDConf;
}

void NodeSelector::setCurrentHostAPDConf(const QVariantMap &config)
{
    PiNodeList nodes = m_discoverer->discoveredNodes();
    if (nodes.isEmpty()) {
        return;
    }
    nodes[m_currentIndex].hostAPDConf = config;
    m_discoverer->setDiscoveredNodes(nodes);


    PiNode node = nodes[m_currentIndex];
    QString mavcmd = "http://" + node.addressString + ":8080/hostapdset?";
    mavcmd.replace("$CLIENT_IP", deviceAddress(node));
    Q_FOREACH(const QVariant &key, config.keys()) {
        mavcmd.append(key.toString() + "=" + config.value(key.toString()).toString());
        if (key != config.keys().last()) {
            mavcmd.append("&");
        }
    }
    qDebug() << "mav command " << mavcmd;
    QVariantMap map;
    sendRequest(mavcmd, map);
}

void NodeSelector::onNewNodeDiscovered(const PiNode &node)
{
        if (node.caps & PiNode::MAVUDP) { // has mav capability
            if (!(node.capsRunning & PiNode::MAVUDP)) { // mav proxy is not running
                QString mavcmd = "http://" + node.addressString + ":8080/mavproxy/?command=" + MAVPROXY_REMOTE_CMD;
                mavcmd.replace("$CLIENT_IP", deviceAddress(node));
                qDebug() << "mav command " << mavcmd;
                QVariantMap map;
                map.insert("requestFor", PiNode::MAVUDP);
                map.insert("nodeIndex", m_currentIndex);
                sendRequest(mavcmd, map);
            }
        }

        if (node.caps & PiNode::AP) { // has ap capability
            hostapdget();
        }

        // start streaming automatically
        if (node.caps & PiNode::PICAM) {
//            startStreaming(node, m_picamOptString, m_recordingStatus);
        }

        // check if its thermal module, if so start thermal
        startThermal(node);

        if(node.caps & (PiNode::PICAM || PiNode::UVC)) {
            m_hasVideo = true;
        }
}

int NodeSelector::startStreaming(int nodeIndex, const QString &optionsString)
{
    PiNodeList nodes = m_discoverer->discoveredNodes();
    if (nodes.count() < nodeIndex -1) {
        // out of range
        return -1;
    }

    return startStreaming(nodes.at(nodeIndex), optionsString, m_recordingStatus);
}

int NodeSelector::startStreaming(const PiNode &node, const QString &optionsString, bool recording)
{
    if (optionsString.isEmpty()) {
        return -1;
    }

    // store for cold start when node appears
    m_picamOptString = optionsString;
    m_recordingStatus = recording;

    QString picamRemoteCommand = PICAM_REMOTE_CMD;
    if (recording) {
        qDebug() << "recording is on";
        picamRemoteCommand = PICAM_REMOTE_CMD_RECORDING;
        picamRemoteCommand.replace("$TIMESTAMP", QDateTime::currentDateTime().toString("dd.MM.yyyy.hh.mm.ss"));
    }

    QString servercmd;
    if (node.caps & PiNode::PICAM) { // has picam capability
        if (optionsString.contains("nostream")) { // check if this goes well with wiered
            servercmd = "http://$SERVER_IP:8080/picam/?command=terminate";
        } else if (optionsString.contains("mapping")) { // check if this goes well with wiered
            servercmd = "http://$SERVER_IP:8080/picam/?command=mapping";
        } else {
            servercmd = "http://$SERVER_IP:8080/picam/?command=" + picamRemoteCommand;
            servercmd = servercmd.replace("$SERVER_IP", node.addressString);
            servercmd = servercmd.replace("$CLIENT_IP", deviceAddress(node));
            servercmd = servercmd.replace("$UDP_PORT", QString::number(node.targetStreamingPort));
            servercmd = servercmd.replace("$OPT_STRING", optionsString);
        }
        QVariantMap map;
        map.insert("requestFor", PiNode::PICAM);
        map.insert("nodeIndex", m_currentIndex);
        qDebug() << "sending out new streaming command " << servercmd;
        sendRequest(servercmd, map);
        return node.targetStreamingPort;
    }
    return -1;
}

void NodeSelector::stopStreaming(int nodeIndex)
{
    PiNodeList nodes = m_discoverer->discoveredNodes();
    if (nodes.count() < nodeIndex -1) {
        // out of range
        return;
    }

    const PiNode& node = nodes.at(nodeIndex);
    terminatePicam(node);
}

bool NodeSelector::startThermal(int nodeIndex)
{
    PiNodeList nodes = m_discoverer->discoveredNodes();
    if (nodes.count() < nodeIndex -1) {
        // out of range
        return false;
    }

    return startThermal(nodes.at(nodeIndex));
}

bool NodeSelector::startThermal(const PiNode &node)
{
    if (node.caps & PiNode::LEPTON) {
        if (!(node.capsRunning & PiNode::LEPTON)) {
            QUrl startUrl("http://" + node.addressString + ":8080/thermalcam/?command=start");
            qDebug() << "thermal server start url " << startUrl;
            QVariantMap map;
            map.insert("requestFor", PiNode::LEPTON);
            map.insert("nodeIndex", m_currentIndex);
//                map.insert("camUrl", mjpegUrl);
            sendRequest(startUrl, map);
        }
        return true;
    }
    return false;
}

void NodeSelector::terminateThermal(int index)
{
    PiNodeList nodes = m_discoverer->discoveredNodes();
    if (nodes.count() < index -1) {
        // out of range
        return;
    }

    terminateThermal(nodes.at(index));
}

// get network interface address corresponding to node that we are dealing with right now.
QString NodeSelector::deviceAddress(const PiNode& node) const
{
    QList<QHostAddress> addresses = QNetworkInterface::allAddresses();
    QHostAddress addr;
    Q_FOREACH(QHostAddress address, addresses) {
        if (address.isLoopback()) {
            continue;
        }

        // netmask is always assumed to be 24 not probably right
        if(address.isInSubnet(QHostAddress::parseSubnet(node.addressString + "/24"))) {
            addr = address;
            break;
        }

    }

    QString address = addr.toString();
    qDebug() << "got the following address for the host device connected to target node" << address;
    return address;
}

void NodeSelector::replyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    reply->deleteLater();
    PiNodeList nodes = m_discoverer->discoveredNodes();
    if (!nodes.size()) {
        return;
    }
    Q_ASSERT(reply);
    if (reply->error() == QNetworkReply::NoError)
    {
        bool ok = false;
        int capibility = reply->property("requestFor").toInt(&ok);
        if (!ok) {
            qDebug() << "generic request return";
            return;
        }

        int index;
        QUrl url;
        switch (capibility) {
        case PiNode::PICAM:
            index = reply->property("nodeIndex").toInt();
            nodes[index].capsRunning |= PiNode::PICAM;
            qDebug() << "picam started without any error";
            break;
        case PiNode::LEPTON:
            index = reply->property("nodeIndex").toInt();
            nodes[index].capsRunning |= PiNode::LEPTON;
//            url = reply->property("camUrl").toUrl();
//            Q_EMIT thermalUrl(url);
            qDebug() << "thermal camera started without any error";
            break;
        case PiNode::MAVUDP:
            index = reply->property("nodeIndex").toInt();
            nodes[index].capsRunning |= PiNode::MAVUDP;
            qDebug() << "mavproxy started without any error";
            break;
        case PiNode::AP:
        {
            index = reply->property("nodeIndex").toInt();
            QString replyString = reply->readAll();
            QStringList replyList = replyString.split("\n");
            qDebug() << replyList;
            QVariantMap keyPair;
            Q_FOREACH(const QString &pair, replyList) {
                if (pair.isEmpty()) {
                    continue;
                }
                QStringList stringPair = pair.split("=");
                qDebug() << stringPair;
                nodes[index].hostAPDConf.insert(stringPair.first(), stringPair.last());
            }
        }
            break;
        default:
            break;
        }
    }
    m_discoverer->setDiscoveredNodes(nodes);
//    Q_FOREACH(const PiNode& node, nodes) {
//        qDebug() << node.hostAPDConf;
//    }
}

void NodeSelector::sendRequest(const QUrl &url, const QVariantMap &properties)
{
    QNetworkRequest request(url);
    QNetworkReply *reply = m_nam->get(request);
    Q_FOREACH(const QString &key, properties.keys()) {
        reply->setProperty(key.toStdString().c_str(), properties.value(key));
    }
    connect(reply, SIGNAL(finished()), this, SLOT(replyFinished()));
}
