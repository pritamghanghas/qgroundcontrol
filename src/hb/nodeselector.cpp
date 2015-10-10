#include "nodeselector.h"
#include <QNetworkInterface>
#include <QNetworkRequest>
#include <QNetworkReply>

static const QString PLAY_CMD("udpsrc port=$PORT ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264");
static const QString PICAM_REMOTE_CMD("raspivid -t 0 -vf -hf -h $RESh -w $RESw -fps $FPS -b $BITRATE -o - | gst-launch-1.0 -v fdsrc ! h264parse ! rtph264pay config-interval=1 pt=96 ! udpsink host=$CLIENT_IP port=$UDP_PORT");
//static const QString MAVPROXY_REMOTE_CMD("screen -S MAVPROXY /usr/local/bin/mavproxy.py --master=127.0.0.1:1440 --baudrate 57600 --out $CLIENT_IP:14550 --aircraft MyCopter");
static const QString MAVPROXY_REMOTE_CMD("/home/pi/ardupilot/ArduCopter/ArduCopter.elf -A udp:$CLIENT_IP:14550 -B /dev/ttyAMA0 > /home/pi/arducopter.log");


NodeSelector::NodeSelector(QNetworkAccessManager *nam, QObject *parent) :
    QObject(parent),
    m_nam(nam),
    m_currentIndex(0)
{
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
    if (node.caps & PiNode::PiCam) {
        qDebug() << "termiante picam at node" << node.addressString;
        QUrl terminateUrl("http://" + node.addressString + ":8080/picam/?command=terminate");
        sendRequest(terminateUrl);
    }
}

void NodeSelector::terminateThermal(const PiNode &node)
{
    if (node.caps & PiNode::Thermal) {
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
    if (node.caps & PiNode::MAVProxy) {
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

void NodeSelector::onNewNodeDiscovered(const PiNode &node)
{
        if (node.caps & PiNode::MAVProxy) { // has mav capability
            if (!(node.capsRunning & PiNode::MAVProxy)) { // mav proxy is not running
                QString mavcmd = "http://" + node.addressString + ":8080/mavproxy/?command=" + MAVPROXY_REMOTE_CMD;
                mavcmd.replace("$CLIENT_IP", deviceAddress());
                qDebug() << "mav command " << mavcmd;
                QVariantMap map;
                map.insert("requestFor", PiNode::MAVProxy);
                map.insert("nodeIndex", m_currentIndex);
                sendRequest(mavcmd, map);
            }
        }

        // check if its thermal module, if so start thermal
        startThermal(node);
}

int NodeSelector::startStreaming(int nodeIndex, int width, int height, int fps, int bitrate)
{
    PiNodeList nodes = m_discoverer->discoveredNodes();
    if (nodes.count() < nodeIndex -1) {
        // out of range
        return -1;
    }

    return startStreaming(nodes.at(nodeIndex), width, height, fps, bitrate);
}

int NodeSelector::startStreaming(const PiNode &node, int width, int height, int fps, int bitrate)
{
    if (node.caps & PiNode::PiCam) { // has picam capability
            if (!(node.capsRunning & PiNode::PiCam)) { //picam is not running
                QString servercmd = "http://$SERVER_IP:8080/picam/?command=" + PICAM_REMOTE_CMD;
                servercmd = servercmd.replace("$SERVER_IP", node.addressString);
                servercmd = servercmd.replace("$CLIENT_IP", deviceAddress());
                servercmd = servercmd.replace("$UDP_PORT", QString::number(node.targetStreamingPort));
                servercmd = servercmd.replace("$RESw", QString::number(width));
                servercmd = servercmd.replace("$RESh", QString::number(height));
                servercmd = servercmd.replace("$FPS", QString::number(fps));
                servercmd = servercmd.replace("$BITRATE", QString::number(bitrate));

                qDebug() << "SERVER CMD: " << servercmd;
                QVariantMap map;
                map.insert("requestFor", PiNode::PiCam);
                map.insert("nodeIndex", m_currentIndex);
                sendRequest(servercmd, map);
            }
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
    if (node.caps & PiNode::Thermal) {
        if (!(node.capsRunning & PiNode::Thermal)) {
            QUrl startUrl("http://" + node.addressString + ":8080/thermalcam/?command=start");
            qDebug() << "thermal server start url " << startUrl;
            QVariantMap map;
            map.insert("requestFor", PiNode::Thermal);
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

QString NodeSelector::deviceAddress() const
{
    QList<QHostAddress> addresses = QNetworkInterface::allAddresses();
    QHostAddress addr;
    Q_FOREACH(QHostAddress address, addresses) {
        if (address.isLoopback()) {
            continue;
        }
        addr = address;
        break;
    }

    QString address = addr.toString();
    qDebug() << "got the following address for the host device" << address;
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
        case PiNode::PiCam:
            index = reply->property("nodeIndex").toInt();
            nodes[index].capsRunning |= PiNode::PiCam;
            qDebug() << "picam started without any error";
            break;
        case PiNode::Thermal:
            index = reply->property("nodeIndex").toInt();
            nodes[index].capsRunning |= PiNode::Thermal;
//            url = reply->property("camUrl").toUrl();
//            Q_EMIT thermalUrl(url);
            qDebug() << "thermal camera started without any error";
            break;
        case PiNode::MAVProxy:
            index = reply->property("nodeIndex").toInt();
            nodes[index].capsRunning |= PiNode::MAVProxy;
            qDebug() << "mavproxy started without any error";
        default:
            break;
        }
    }
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
