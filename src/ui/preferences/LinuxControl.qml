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
import QtQuick.Layouts 1.2

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

QGCView {
    id:                 _hoverbirdsView
    viewPanel:          panel
    anchors.fill:       parent

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    readonly property int confirmShutdown:        1
    readonly property int confirmRestart:         2

    readonly property real _margins:      ScreenTools.defaultFontPixelHeight

    property real _fontPointSize: ScreenTools.isMobile ? ScreenTools.largeFontPointSize : ScreenTools.defaultFontPointSize

    property int    confirmActionCode

    Timer {
        id:             confirmSlideHideTimer
        interval:       7000
        running:        true
        onTriggered:    _OSControlConfirm.visible = false
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



    QGCViewPanel {
        id:             panel
        anchors.fill:   parent

        QGCFlickable {
            clip:               true
            anchors.fill:       parent
            contentHeight:      flowLayout.height
            contentWidth:       flowLayout.width

            Flow {
                id:         flowLayout
                width:      panel.width // parent.width doesn't work for some reason
                spacing:    _margins

                Column {
                    spacing: _margins / 2

                    QGCLabel {
                        id:         piControlLabel
                        text:       "Pi Control"
                        font.family: ScreenTools.demiboldFontFamily
                    }


                    Rectangle {
                        id:                     piControlActions
//                        anchors.margins:        _margins
                        color:                  qgcPal.windowShade

                        Column {
                            spacing:            _margins / 2

                            QGCButton {
                                text:       "Shutdown Controller"
                                onClicked: confirmAction(confirmShutdown)
                            }
                            QGCButton {
                                text:       "Restart Controller"
                                onClicked: confirmAction(confirmRestart)
                            }
                        }

                    } // Rectangle - System Control
                } // OS control column

                Column {
                    spacing: _margins / 2

                    QGCLabel {
                        id:                 _wiredLimits
                        text:               "Wire Limits"
                        font.family:        ScreenTools.demiboldFontFamily
                    }

                    Rectangle {
                        id:                 _wireLimitSettings
                        anchors.margins:    _margins
                        color:              qgcPal.windowShade

                        Grid {
                            columns : 2
                            spacing : _margins/2

                        QGCLabel {
                            id: panSweepAngleLabel
                            text : "Pan sweep angle (degree)"
                        }
                        QGCTextField {
                            id: panSweepAngleField
                            // limiting to 160 degree max as Ardupilot doesn't seem to honour direction
                            // it leads to trouble when moving angle cloe to 180 or more
                            validator: IntValidator { bottom: 5; top: 160 }
                            text: QGroundControl.hbSettings.value("panSweepAngle", 20)
                            onEditingFinished: {
                                QGroundControl.hbSettings.setValue("panSweepAngle", text);
                            }
                        }

                        QGCLabel {
                            id: panSweepSpeedLabel
                            text : "sweep speed (degree/s)"
                        }
                        QGCTextField {
                            id: panSweepSpeedField
                            validator: IntValidator { bottom: 1; top: 160 }
                            text: QGroundControl.hbSettings.value("panSweepSpeed", 5)
                            onEditingFinished: {
                                QGroundControl.hbSettings.setValue("panSweepSpeed", text);
                            }
                        }

                        QGCLabel {
                            id: wiredMinAltitudeLabel
                            text : "Wired Min Alt (meter)";
                        }
                        QGCTextField {
                            id: wiredMinAltitudeLabelField
                            validator: IntValidator { bottom: 5; top: 2000 }
                            text: QGroundControl.hbSettings.value("wiredMinAltitude", 5)
                            onEditingFinished: {
                                QGroundControl.hbSettings.setValue("wiredMinAltitude", text);
                            }
                        }

                        QGCLabel {
                            id: wiredMaxAltitudeLabel
                            text : "Wired Max Alt (meter)";
                        }
                        QGCTextField {
                            id: wiredMaxAltitudeLabelField
                            validator: IntValidator { bottom: 5; top: 2000 }
                            text: QGroundControl.hbSettings.value("wiredMaxAltitude", 60)
                            onEditingFinished: {
                                QGroundControl.hbSettings.setValue("wiredMaxAltitude", text);
                            }
                        }
                        }
                    } // Rectangle altitude control
                }
            } // flow
        } // QGCFlickable
    } // QGCViewPanel
} // QGCView
