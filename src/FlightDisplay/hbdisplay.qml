/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2
import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Layouts          1.2

import QGroundControl                           1.0
import QGroundControl.ScreenTools               1.0
import QGroundControl.Controls                  1.0
import QGroundControl.Palette                   1.0
import QGroundControl.Vehicle                   1.0
import QGroundControl.FlightMap                 1.0

Item {
    id: _root

    property var    qgcView

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _videoReceiver:         QGroundControl.videoManager.videoReceiver
    property bool   _recordingVideo:        _videoReceiver && _videoReceiver.recording
    property bool   _mainIsMap:             QGroundControl.videoManager.hasVideo ? QGroundControl.loadBoolGlobalSetting(_mainIsMapKey,  true) : true
//    property bool   _hasVideoNode:           QGroundControl.nodeSelector.hasVideoNode // this won't work, there is no notify
    property bool   _hasVideoNode:           true // we should make it dynamic later.
    property real   _margins:               ScreenTools.defaultFontPixelWidth

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    // enums for camera control
    readonly property int controlTypeNone: 0
    readonly property int controlTypePitchDown: 1
    readonly property int controlTypePitchUp: 2
    readonly property int controlTypeYawRight: 3
    readonly property int controlTypeYawLeft: 4

    property int controlType: controlTypeNone

    property int  _cameraControlPressedSince: 0 // miliseconds


    // rule of thumb for bitrate is
    // 1 is low motion, 4 is lot of motion like uav
    // frame w * frame h * fps * motion factor (1,2,4) * 0.07 //bps

    ListModel {
        id: bitrateList

        ListElement {
            text: "15mbps"
            bitrate: 15000000
        }
        ListElement {
            text: "10mbps"
            bitrate: 10000000
        }
        ListElement {
            text: "5mbps"
            bitrate: 5000000
        }
        ListElement {
            text: "2mbps"
            bitrate: 200000
        }
        ListElement {
            text: "1mbps"
            bitrate: 1000000
        }
        ListElement {
            text: "0.7mbps"
            bitrate: 700000
        }
        ListElement {
            text: "0.5mbps"
            bitrate: 500000
        }
        ListElement {
            text: "0.2mbps"
            bitrate: 200000
        }
    }

    ListModel {
        id: iframeList

        ListElement { text: "i30"; frames: 30; }
        ListElement { text: "i20"; frames: 20; }
        ListElement { text: "i10"; frames: 10; }
        ListElement { text: "i5"; frames: 5; }
    }

    ListModel {
        id: resolutionList

        ListElement {
            text:           "1080p30f";
            width:          1920;
            height:         1080;
            fps:            30;
            bitrateIndex:   0;
            // desired birate of 17mps
        }

        ListElement {
            text:           "720p49f";
            width:          1296;
            height:          730;
            fps:             49;
            bitrateIndex:    1;
            // desired birtae 12mpbs
        }
        ListElement {
            text:           "720p30f";
            width:          1296;
            height:          730;
            fps:             30;
            bitrateIndex:    2;
            // desired bitrate of 7mbps
        }
        ListElement {
            text:           "640p60f";
            width:          640;
            height:         480;
            fps:            60;
            bitrateIndex:    2;
            // desired birtae of 5mbps
        }
        ListElement {
            text:           "640p30f";
            width:          640;
            height:         480;
            fps:            30;
            bitrateIndex:    3;
            // desired birate of 2.5mps
        }
        ListElement {
            text:           "640p15f";
            width:          640;
            height:         480;
            fps:            15;
            bitrateIndex:    4;
            // desired bitrate of 1.3mps
        }
//        ListElement {
//            text: "photo";
//        }
    }

    ListModel {
        id: exposureModesList
        ListElement { text: "auto";}
        ListElement { text: "night";}
        ListElement { text: "nightpreview"; }
        ListElement { text: "backlight"; }
        ListElement { text: "spotlight"; }
        ListElement { text: "sports";}
        ListElement { text: "snow";}
        ListElement { text: "beach";}
        ListElement { text: "verylong";}
        ListElement { text: "fixedfps";}
        ListElement { text: "antishake";}
        ListElement { text: "fireworks";}
    }


    ListModel {
        id: awbModesList
        ListElement { text: "auto"; }
        ListElement { text: "off"; }
        ListElement { text: "sun"; }
        ListElement { text: "cloud"; }
        ListElement { text: "shade"; }
        ListElement { text: "tugsten"; }
        ListElement { text: "fluorescent"; }
        ListElement { text: "incadescent"; }
        ListElement { text: "flash"; }
        ListElement { text: "horizon"; }
        ListElement { text: "antishake"; }
        ListElement { text: "fireworks"; }
    }

    ListModel {
        id: meteringModesList
        ListElement { text: "average"; }
        ListElement { text: "spot"; }
        ListElement { text: "backlit"; }
        ListElement { text: "matrix"; }
    }

    ListModel {
        id: recordingModesList
        ListElement { text: "rec on"; }
        ListElement { text: "rec off"; }
    }

    ListModel {
        id: orientationModeList

        ListElement {
            text: "none"
            command: ""
        }

        ListElement {
            text: "vflip"
            command: " -vf "
        }

        ListElement {
            text: "hflip"
            command: " -hf "
        }

        ListElement {
            text: "vhflip"
            command: " -hf -vf "
        }
    }

    function onModeChange()
    {
        if (_videoReceiver && _hasVideoNode) {
            var metringMode = meteringModesList.get(meteringComboBox.currentIndex).text;
            var awbMode = awbModesList.get(awbComboBox.currentIndex).text;
            var exposureMode = exposureModesList.get(exposureComboBox.currentIndex).text;
            var width = resolutionList.get(resolutionSelectionComboBox.currentIndex).width;
            var height = resolutionList.get(resolutionSelectionComboBox.currentIndex).height;
            var fps = resolutionList.get(resolutionSelectionComboBox.currentIndex).fps;
            var bitrate = bitrateList.get(bitrateSelectionComboBox.currentIndex).bitrate;
            var iframeRate = iframeList.get(iframeSelectionComboBox.currentIndex).frames;
            var flipMode = orientationModeList.get(orientationSelectionComboBox.currentIndex).command;
            var recording = recordingModesList.get(recordingComboBox.currentIndex).text;
            var optString = "-mm " + metringMode + " -awb " + awbMode + " -g " + iframeRate + " -ex " + exposureMode + " -w " + width + " -h " + height + " -fps " + fps + " -b " + bitrate + flipMode;
            console.log("lets start the video with following optons: " + optString);
            _videoReceiver.stop();
            _videoReceiver.delayedStart(optString, recording == "rec on");
        }
    }

    function calculateMovement()
    {
        console.log("calculating next move");
        _cameraControlPressedSince += pressTimer.interval
        switch(controlType)
        {
        case controlTypePitchDown:
            onIncrementPitch()
            break
        case controlTypePitchDown:
            onDecrementPitch()
            break
        case controlTypeYawRight:
            onIncrementYaw()
            break
        case controlTypeYawLeft:
            onDecrementYaw()
            break;
        case controlTypeNone:
        default:
            break
        }
    }

    function stepSize()
    {
        if (_cameraControlPressedSince < 500) {
            return 1;
        } else {
            return 3;
        }
    }

    function onIncrementYaw()
    {
        console.log("move yaw right by ", stepSize())
        panSweepButton.checked = false
        _activeVehicle.doSweepYaw(0,0)
        _activeVehicle.doChangeYaw(stepSize(), 1, true, 1);
    }

    function onDecrementYaw()
    {
        console.log("move yaw left by ", stepSize())
        panSweepButton.checked = false
        _activeVehicle.doSweepYaw(0,0)
        _activeVehicle.doChangeYaw(stepSize(), 1, true, -1);
    }

    function onIncrementPitch()
    {
        console.log("move pitch down by ", stepSize())
        // send servo set probably
    }

    function onDecrementPitch()
    {
        console.log("move pitch up by ", stepSize())
        // send servo set probably
    }

    function startPressTimer()
    {
        if(!pressTimer.running) {
            _cameraControlPressedSince = 0
            calculateMovement()
            pressTimer.start()
        }
    }

    function stopPressTimer()
    {
        if(pressTimer.running) {
            _cameraControlPressedSince = 0
            pressTimer.stop()
        }
    }

    Timer {
        id: pressTimer
        interval: 20
        running:  false
        repeat:   true
        onTriggered: {
           calculateMovement();
        }
    }

    Column {
        id:                         toolColumn
        visible:                    !_mainIsMap && _hasVideoNode
        anchors.margins:            _margins
        anchors.topMargin:          _margins*2
        anchors.left:               parent.left
        anchors.top:                parent.top
        spacing:                    _margins

        RoundButton {
            id: videoSettings
            buttonImage: "/qmlimages/cameraSettings.svg"
            buttonAnchors.margins:  width*0.15
            z:            QGroundControl.zOrderWidgets
        }

        // camera sweep code disable for now.
        RoundButton {
            id: cameraAngleControlButton
            buttonImage: "/qmlimages/look.svg"
            buttonAnchors.margins:  width*0.15
            z:            QGroundControl.zOrderWidgets
            visible: false
        }

          // yaw sweep code, disabling for the time being
        RoundButton {
            id: panSweepButton
            buttonImage: "/qmlimages/rotate.svg"
            visible: QGroundControl.hbSettings.value("enableWire", false) === true
            buttonAnchors.margins:  width*0.15
            z:            QGroundControl.zOrderWidgets
            onClicked: {
                if(checked) {
                    _activeVehicle.doSweepYaw(QGroundControl.hbSettings.value("panSweepAngle", 20), QGroundControl.hbSettings.value("panSweepSpeed", 5));
                } else {
                    _activeVehicle.doSweepYaw(0, 0);
                }
            }
        }
    }

    // NOTE:: this is second part of camera diretion control pad ui, currently hidden
    Rectangle {
        id: cameraControls
        radius:         ScreenTools.defaultFontPixelHeight
        border.width:   ScreenTools.defaultFontPixelHeight * 0.0625
        border.color:   "white"
        anchors.left:   toolColumn.right
        y:              cameraAngleControlButton.y
        anchors.margins:        _margins*2
        height:                 _margins*20
        width:                  _margins*20
        color:                  "transparent"
        visible:                cameraAngleControlButton.checked && !_mainIsMap

        Item {
            anchors.left: parent.left
            width: parent.width/3
            height: parent.height/3
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins:        _margins
            Image {
                id: leftArrow
                rotation: 90
                width: parent.width/1.5
                height: parent.height/1.5
                fillMode: Qt.KeepAspectRatio
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                source: "/qmlimages/arrow_dark.svg"
            }
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    console.log("left pressed")
                    mouse.accepted = true
                    controlType = controlTypeYawLeft
                    startPressTimer()
                }
                onReleased: {
                    console.log("left released")
                    mouse.accepted = true
                    controlType = controlTypeNone
                    stopPressTimer()
                }
            }
        }


        Item {
            anchors.top: parent.top
            width: parent.width/3
            height: parent.height/3
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins:        _margins
            Image {
                id: topArrow
                rotation: 180
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width/1.5
                height: parent.height/1.5
                fillMode: Qt.KeepAspectRatio
                source: "/qmlimages/arrow_dark.svg"
            }
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    console.log("top pressed")
                    mouse.accepted = true
                    controlType = controlTypePitchUp
                    startPressTimer()
                }
                onReleased: {
                    console.log("top released")
                    mouse.accepted = true
                    controlType = controlTypeNone
                    stopPressTimer()
                }
            }
        }

        Item {
            anchors.right: parent.right
            width: parent.width/3
            height: parent.height/3
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins:        _margins
            Image {
                id: rightArrow
                rotation: 270
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width/1.5
                height: parent.height/1.5
                fillMode: Qt.KeepAspectRatio
                source: "/qmlimages/arrow_dark.svg"
            }
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    console.log("right pressed")
                    mouse.accepted = true
                    controlType = controlTypeYawRight
                    startPressTimer()
                }
                onReleased: {
                    console.log("right released")
                    mouse.accepted = true
                    controlType = controlTypeNone
                    stopPressTimer()
                }
            }
        }

        Item {
            anchors.bottom: parent.bottom
            width: parent.width/3
            height: parent.height/3
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins:        _margins
            Image {
                id: downArrow
                fillMode: Qt.KeepAspectRatio
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width/1.5
                height: parent.height/1.5
                source: "/qmlimages/arrow_dark.svg"
            }
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    console.log("down pressed")
                    mouse.accepted = true
                    controlType = controlTypePitchUp
                    startPressTimer()
                }
                onReleased: {
                    console.log("down released")
                    mouse.accepted = true
                    controlType = controlTypeNone
                    stopPressTimer()
                }
            }
        }
    }

    Item {
        id : combo
//        width: parent.width*0.47
        y: videoSettings.y + _margins*2
        anchors.left: toolColumn.right
//        anchors.top: toolColumn.top
        anchors.margins: _margins
//        x: parent.width - width;
//        y: parent.height * 0.12;
        visible: videoSettings.checked && !_mainIsMap;

        Row {
            spacing: _margins
            layoutDirection: Qt.LeftToRight
            anchors.margins: _margins


            QGCComboBox {
                id:         meteringComboBox
//                anchors.leftMargin: _margins*2
//                anchors.margins: _margins
//                width: combo.width*0.17
                visible:    false
                model:      meteringModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:    recordingComboBox
//                anchors.margins: _margins
//                anchors.leftMargin: _margins*2
//                width: combo.width*0.12
                visible:    true
                model:      recordingModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         exposureComboBox
//                width: combo.width*0.16
                visible:    true
                model:      exposureModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         awbComboBox
//                width: combo.width*0.13
                visible:    true
                model:      awbModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         resolutionSelectionComboBox
//                width:      combo.width*0.14
                visible:    true
                model:      resolutionList

                onCurrentIndexChanged: {
//                    onResolutionChange();
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         bitrateSelectionComboBox
//                width: combo.width*0.13
                visible:    true
                model:      bitrateList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         iframeSelectionComboBox
//                width: combo.width*0.08
                visible:    true
                model:      iframeList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id: orientationSelectionComboBox
//                width: combo.width*0.11
                visible: true
                model: orientationModeList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }
        }
    }


    Component.onCompleted: {
        // some fidgeting to do to get the combo box working correctly. otherwise the model data
        // comes out to be invalid
        meteringComboBox.currentIndex = 1;
        meteringComboBox.currentIndex = 0;
        recordingComboBox.currentIndex = 1;
//        recordingComboBox.currentIndex = 0;
        exposureComboBox.currentIndex = 1;
        exposureComboBox.currentIndex = 0;
        awbComboBox.currentIndex = 1;
        awbComboBox.currentIndex = 0;
        resolutionSelectionComboBox.currentIndex = 4;
        bitrateSelectionComboBox.currentIndex = 4;
        iframeSelectionComboBox.currentIndex = 1;
        iframeSelectionComboBox.currentIndex = 0;
        orientationSelectionComboBox.currentIndex = 1;
        orientationSelectionComboBox.currentIndex = 0;

        if(/*videoBackground.display && */_videoReceiver) {
            resolutionSelectionComboBox.currentIndex = 4;
//            onModeChange();
        }
    }

    onVisibleChanged: {
        if(_videoReceiver) {
//               onModeChange();
        }
    }

//    onRunVideoChanged: {
//        if(videoBackground.receiver && videoBackground.display) {
//            if(videoBackground.runVideo) {
//                onModeChange();
//            } else {
//                videoBackground.receiver.stop();
//            }
//        }
//    }

}
