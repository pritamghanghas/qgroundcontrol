/*=====================================================================

 QGroundControl Open Source Ground Control Station

 (c) 2009 - 2015 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>

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

import QtQuick 2.3

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

Rectangle {
    color: qgcPal.window

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    readonly property int confirmShutdown:        1
    readonly property int confirmRestart:         2
    readonly property real _margins:              ScreenTools.defaultFontPixelHeight / 2
    property real _fontPointSize: ScreenTools.isMobile ? ScreenTools.largeFontPointSize : ScreenTools.defaultFontPointSize

    property int    confirmActionCode

    Timer {
        id:             confirmSlideHideTimer
        interval:       7000
        running:        true
        onTriggered:    _OSControlConfirm.visible = false
    }

    Column {
        anchors.margins:    ScreenTools.defaultFontPixelHeight
        anchors.left:       parent.left
        anchors.top:        parent.top
        spacing:            ScreenTools.defaultFontPixelHeight

        QGCButton {
            text:       "Shutdown Controller"
            onClicked: confirmAction(confirmShutdown)
        }
        QGCButton {
            text:       "Restart Controller"
            onClicked: confirmAction(confirmRestart)
        }
    }

    // Action confirmation control
    SliderSwitch {
        id:                         _OSControlConfirm
        anchors.bottomMargin:       _margins
        anchors.bottom:             parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        visible:                    false
        z:                          QGroundControl.zOrderWidgets
        fontPointSize:              _fontPointSize

        onAccept: {
            _OSControlConfirm.visible = false
            actionConfirmed()
            confirmSlideHideTimer.stop()
        }

        onReject: {
            _OSControlConfirm.visible = false
            confirmSlideHideTimer.stop()
        }

    }

    function actionConfirmed() {
        confirmSlideHideTimer.stop()
        _OSControlConfirm.visible = false
        switch (confirmActionCode) {
        case confirmShutdown:
            console.log("shutting down")
            QGroundControl.nodeSelector.shutdownAll();
            break;
        case confirmRestart:
            console.log("restarting")
            QGroundControl.nodeSelector.restartAll();
            break;
        default:
            console.warn(qsTr("Internal error: unknown confirmActionCode"), confirmActionCode)
        }
    }

    function confirmAction(actionCode) {
        confirmSlideHideTimer.start()
        _OSControlConfirm.visible = true
        confirmActionCode = actionCode
        switch (confirmActionCode) {
        case confirmShutdown:
            _OSControlConfirm.confirmText = qsTr("Shutdown")
            break;
        case confirmRestart:
            _OSControlConfirm.confirmText = qsTr("Restart")
            break;
        }
    }
} // rectangle
