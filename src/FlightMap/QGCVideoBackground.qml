/*=====================================================================

QGroundControl Open Source Ground Control Station

(c) 2009, 2015 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>

This file is part of the QGROUNDCONTROL project

    QGROUNDCONTROL is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    QGROUNDCONTROL is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with QGROUNDCONTROL. If not, see <http://www.gnu.org/licenses/>.

======================================================================*/

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
    property var runVideo:  false
    surface: display

    ListModel {
        id: resolutionList

        ListElement {
            text:           "1080 30p 4mbps";
            width:          1920;
            height:         1080;
            bitrate:        4000000;
            fps:            30;
        }
        ListElement {
            text:           "1080 30p 2mbps";
            width:          1920;
            height:         1080;
            bitrate:        2000000;
            fps:            30;
        }
        ListElement {
            text:           "1080 10p 1mbps";
            width:          1920;
            height:         1080;
            bitrate:        2000000;
            fps:            30;
        }
        ListElement {
            text:           "1080 4p 0.5mbps";
            width:          1920;
            height:         1080;
            bitrate:        2000000;
            fps:            30;
        }
        ListElement {
            text:           "720 49p 4mbps";
            width:          1296;
            height:          730;
            bitrate:        4000000;
            fps:             49;
        }
        ListElement {
            text:           "720 49p 2mbps";
            width:          1296;
            height:          730;
            bitrate:        2000000;
            fps:             49;
        }
        ListElement {
            text:           "720 49p 1mbps";
            width:          1296;
            height:          730;
            bitrate:        1000000;
            fps:             49;
        }
        ListElement {
            text:           "720 30p 1mbps";
            width:          1296;
            height:          730;
            bitrate:        1000000;
            fps:             49;
        }
        ListElement {
            text:           "720 15p 0.7mbps";
            width:          1296;
            height:          730;
            bitrate:        1000000;
            fps:             49;
        }
        ListElement {
            text:           "720 4p 0.5mbps";
            width:          1296;
            height:          730;
            bitrate:        1000000;
            fps:             49;
        }
        ListElement {
            text:           "640 60p 0.7mbps";
            width:          640;
            height:         480;
            bitrate:        700000;
            fps:            90;
        }
        ListElement {
            text:           "640 30p 0.5mbps";
            width:          640;
            height:         480;
            bitrate:        500000;
            fps:            30;
        }
        ListElement {
            text:           "640 15p 0.5mbps";
            width:          640;
            height:         480;
            bitrate:        300000;
            fps:            15;
        }
        ListElement {
            text:           "640 15p 0.3mbps";
            width:          640;
            height:         480;
            bitrate:        300000;
            fps:            15;
        }
        ListElement {
            text:           "320 90p 0.5mbps";
            width:          320;
            height:         240;
            bitrate:        500000;
            fps:            90;
        }
        ListElement {
            text:           "320 60p 0.4mbps";
            width:          320;
            height:         240;
            bitrate:        400000;
            fps:            60;
        }
        ListElement {
            text:           "320 30p 0.3mbps";
            width:          320;
            height:         240;
            bitrate:        300000;
            fps:            30;
        }
        ListElement {
            text:           "320 15p 0.1mbps";
            width:          320;
            height:         240;
            bitrate:        100000;
            fps:            15;
        }
        ListElement {
            text:           "160 90p 0.2mbps";
            width:          160;
            height:         120;
            bitrate:        100000;
            fps:            90;
        }
        ListElement {
            text:           "160 60p 0.15mbps";
            width:          160;
            height:         120;
            bitrate:        100000;
            fps:            90;
        }
        ListElement {
            text:           "160 30p 0.1mbps";
            width:          160;
            height:         120;
            bitrate:        100000;
            fps:            30;
        }
        ListElement {
            text:           "160 15p 0.05mbps";
            width:          160;
            height:         120;
            bitrate:        50000;
            fps:            15;
        }
        ListElement {
            text:           "160 15p 0.03mbps";
            width:          160;
            height:         120;
            bitrate:        30000;
            fps:            8;
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

    function onModeChange()
    {
        if (videoBackground.visible) {
            var metringMode = meteringModesList.get(meteringComboBox.currentIndex).text;
            var awbMode = awbModesList.get(awbComboBox.currentIndex).text;
            var exposureMode = exposureModesList.get(exposureComboBox.currentIndex).text;
            var width = resolutionList.get(resolutionSelectionComboBox.currentIndex).width;
            var height = resolutionList.get(resolutionSelectionComboBox.currentIndex).height;
            var fps = resolutionList.get(resolutionSelectionComboBox.currentIndex).fps;
            var bitrate = resolutionList.get(resolutionSelectionComboBox.currentIndex).bitrate;
            var optString = "-mm " + metringMode + " -awb " + awbMode + " -ex " + exposureMode + " -w " + width + " -h " + height + " -fps " + fps + " -b " + bitrate;
            console.log("lets start the video with following optons: " + optString);
            videoBackground.receiver.start(optString)
        }
    }

    Item {
        id : combo
        width: parent.width*0.4
        anchors.right: parent.right
        x: parent.width - width;
        y: parent.height * 0.08;
        visible: !_mainIsMap;

        Row {
            spacing: 10
            layoutDirection: Qt.LeftToRight


            QGCComboBox {
                id:         meteringComboBox
                width: combo.width*0.2
                visible:    true
                model:      meteringModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         exposureComboBox
                width: combo.width*0.22
                visible:    true
                model:      exposureModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         awbComboBox
                width: combo.width*0.22
                visible:    true
                model:      awbModesList

                onCurrentIndexChanged: {
                    onModeChange();
                }
            }

            QGCComboBox {
                id:         resolutionSelectionComboBox
                width: combo.width*0.3
                visible:    true
                model:      resolutionList

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
        exposureComboBox.currentIndex = 1;
        exposureComboBox.currentIndex = 0;
        awbComboBox.currentIndex = 1;
        awbComboBox.currentIndex = 0;
        resolutionSelectionComboBox.currentIndex = 1;
        resolutionSelectionComboBox.currentIndex = 7;
        videoBackground.visible = true;

        if(videoBackground.display && videoBackground.receiver) {
            resolutionSelectionComboBox.currentIndex = 7;
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

    onRunVideoChanged: {
        if(videoBackground.receiver && videoBackground.display) {
            if(videoBackground.runVideo) {
                onModeChange();
            } else {
                videoBackground.receiver.stop();
            }
        }
    }
}
