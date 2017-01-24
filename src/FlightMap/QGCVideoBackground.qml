/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/**
 * @file
 *   @brief QGC Video Background
 *   @author Gus Grubba <mavlink@grubba.com>
 */

import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.2
import QGroundControl.QgcQtGStreamer 1.0
import QGroundControl.ScreenTools    1.0
import QGroundControl.Controls       1.0

VideoItem {
    id: videoBackground
    property var display
    property var receiver
    surface: display

    ListModel {
        id: bitrateList

        ListElement {
            text: "4mbps"
            bitrate: 4000000
        }
        ListElement {
            text: "2mbps"
            bitrate: 2000000
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
        }

        ListElement {
            text:           "720p49f";
            width:          1296;
            height:          730;
            fps:             49;
        }
        ListElement {
            text:           "720p30f";
            width:          1296;
            height:          730;
            fps:             30;
        }
        ListElement {
            text:           "640p60f";
            width:          640;
            height:         480;
            fps:            60;
        }
        ListElement {
            text:           "640p30f";
            width:          640;
            height:         480;
            fps:            30;
        }
        ListElement {
            text:           "640p15f";
            width:          640;
            height:         480;
            fps:            15;
        }
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
        if (videoBackground.visible) {
            var metringMode = meteringModesList.get(meteringComboBox.currentIndex).text;
            var awbMode = awbModesList.get(awbComboBox.currentIndex).text;
            var exposureMode = exposureModesList.get(exposureComboBox.currentIndex).text;
            var width = resolutionList.get(resolutionSelectionComboBox.currentIndex).width;
            var height = resolutionList.get(resolutionSelectionComboBox.currentIndex).height;
            var fps = resolutionList.get(resolutionSelectionComboBox.currentIndex).fps;
            var bitrate = bitrateList.get(resolutionSelectionComboBox.currentIndex).bitrate;
            var iframeRate = iframeList.get(iframeSelectionComboBox.currentIndex).frames;
            var flipMode = orientationModeList.get(orientationSelectionComboBox.currentIndex).command;
            var recording = recordingModesList.get(recordingComboBox.currentIndex).text;
            var optString = "-mm " + metringMode + " -awb " + awbMode + " -g " + iframeRate + " -ex " + exposureMode + " -w " + width + " -h " + height + " -fps " + fps + " -b " + bitrate + flipMode;
            console.log("lets start the video with following optons: " + optString);
            videoBackground.receiver.start(optString, recording == "rec on");
        }
    }

    Item {
        id : combo
        width: parent.width*0.47
        anchors.right: parent.right
        x: parent.width - width;
        y: parent.height * 0.12;
        visible: !_mainIsMap;

        Row {
            spacing: 10
            layoutDirection: Qt.LeftToRight


            QGCComboBox {
                id:         meteringComboBox
                width: combo.width*0.17
                visible:    false
                model:      meteringModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:    recordingComboBox
                width: combo.width*0.12
                visible:    true
                model:      recordingModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         exposureComboBox
                width: combo.width*0.16
                visible:    true
                model:      exposureModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         awbComboBox
                width: combo.width*0.13
                visible:    true
                model:      awbModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         resolutionSelectionComboBox
                width:      combo.width*0.14
                visible:    true
                model:      resolutionList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         bitrateSelectionComboBox
                width: combo.width*0.13
                visible:    true
                model:      bitrateList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         iframeSelectionComboBox
                width: combo.width*0.08
                visible:    true
                model:      iframeList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id: orientationSelectionComboBox
                width: combo.width*0.11
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
        videoBackground.visible = false;
        meteringComboBox.currentIndex = 1;
        meteringComboBox.currentIndex = 0;
        recordingComboBox.currentIndex = 1;
//        recordingComboBox.currentIndex = 0;
        exposureComboBox.currentIndex = 1;
        exposureComboBox.currentIndex = 0;
        awbComboBox.currentIndex = 1;
        awbComboBox.currentIndex = 0;
        resolutionSelectionComboBox.currentIndex = 4;
        bitrateSelectionComboBox.currentIndex = 2;
        iframeSelectionComboBox.currentIndex = 1;
        iframeSelectionComboBox.currentIndex = 0;
        orientationSelectionComboBox.currentIndex = 1;
        orientationSelectionComboBox.currentIndex = 0;
        videoBackground.visible = true;

        if(videoBackground.display && videoBackground.receiver) {
            resolutionSelectionComboBox.currentIndex = 4;
        }

        if(videoBackground.runVideo && videoBackground.receiver) {
            onModeChange();
        }
    }

    onVisibleChanged: {
        if(videoBackground.receiver && videoBackground.display) {
            if(videoBackground.runVideo) {
               onModeChange();
            }
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
