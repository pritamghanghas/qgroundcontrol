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
import QGroundControl.QgcQtGStreamer 1.0
import QGroundControl.ScreenTools    1.0
import QGroundControl.Controls       1.0

VideoItem {
    id: videoBackground
    property var display
    property var receiver
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
            text:           "640 90p 0.7mbps";
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
            text:           "640 15p 0.3mbps";
            width:          640;
            height:         480;
            bitrate:        300000;
            fps:            15;
        }
    }

    QGCComboBox {
        id:         resolutionSelectionComboBox
        width: 150
        x: parent.width - width - 10;
        y: parent.height - height - 10;
        visible:    true
        model:      resolutionList

        onCurrentIndexChanged: {
            console.debug("lets start the video with resolution" + resolutionList.get(currentIndex).width);
            videoBackground.receiver.start(resolutionList.get(currentIndex).width, resolutionList.get(currentIndex).height,
                                           resolutionList.get(currentIndex).fps, resolutionList.get(currentIndex).bitrate);
        }

    }


    Component.onCompleted: {
        if(videoBackground.visible && videoBackground.receiver) {
            resolutionSelectionComboBox.currentIndex = 4;
        }
    }

    onVisibleChanged: {
        if(videoBackground.receiver && videoBackground.display) {
            if(videoBackground.visible) {
                videoBackground.receiver.start(resolutionList.get(resolutionSelectionComboBox.currentIndex).width,
                                               resolutionList.get(resolutionSelectionComboBox.currentIndex).height,
                                               resolutionList.get(resolutionSelectionComboBox.currentIndex).
                                               fps,
                                               resolutionList.get(resolutionSelectionComboBox.currentIndex).bitrate);
            } else {
                videoBackground.receiver.stop();
            }
        }
    }
}
