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

QGCView {
    id:                 _hoverbirdsView
    viewPanel:          panel
    anchors.fill:       parent

    QGCPalette { id: palette; colorGroupEnabled: enabled }

    property real _margins: ScreenTools.defaultFontPixelHeight

    QGCViewPanel {
        id:             panel
        anchors.fill:   parent
        anchors.margins: _margins

        QGCFlickable {
            clip:               true
            anchors.fill:       parent
            contentHeight:      wiredMaxAltitudeLabelField.y + wiredMaxAltitudeLabelField.height + _margins
            contentWidth:       wiredMaxAltitudeLabelField.x + wiredMaxAltitudeLabelField.width + _margins

            QGCLabel {
                id:         piControlLabel
                anchors.leftMargin: _margins
                anchors.topMargin: _margins
                text:       "System Control"
                font.weight: Font.DemiBold
            }

            Rectangle {
                id:                     piControlActions
                anchors.topMargin:      _margins / 2
                anchors.rightMargin:    _margins
                anchors.left:           parent.left
                anchors.top:            piControlLabel.bottom
                width:                  shutdownButton.x + shutdownButton.width + _margins
                height:                 restartButton.y + restartButton.height + _margins
                color:                  palette.windowShade

                QGCButton {
                    id:                 shutdownButton
                    anchors.margins:    _margins
                    anchors.left:       parent.left
                    anchors.top:        parent.top
                    text:               "Shutdown Controller"
                    onClicked:          QGroundControl.nodeSelector.shutdownAll();
                }
                QGCButton {
                    id:             restartButton
                    anchors.topMargin: _margins
                    anchors.top:   shutdownButton.bottom
                    anchors.left: shutdownButton.left
                    anchors.right: shutdownButton.right
                    text:           "Restart Controller"
                    onClicked: QGroundControl.nodeSelector.restartAll();
                }
            } // Rectangle - System Control

            QGCLabel {
                id:                 _wiredLimits
                anchors.leftMargin: _margins
                anchors.left:       piControlActions.right
                anchors.top:        piControlLabel.top
                text:               "Wire Limits"
                font.weight:        Font.DemiBold
            }

            Rectangle {
                id:                 _wireLimitSettings
                anchors.topMargin:  _margins / 2
                anchors.left:       _wiredLimits.left
                anchors.top:        _wiredLimits.bottom
                width:              panSweepAngleField.x + panSweepAngleField.width + _margins
                height:             wiredMaxAltitudeLabelField.y + wiredMaxAltitudeLabelField.height + _margins
                color:              palette.windowShade

                QGCLabel {
                    id: panSweepAngleLabel
                    text : "Pan sweep angle"
                    anchors.margins: _margins
                    anchors.left: parent.left
                    anchors.baseline: panSweepAngleField.baseline
                }
                QGCTextField {
                    id: panSweepAngleField
                    validator: IntValidator { bottom: 5; top: 360 }
                    anchors.margins: _margins
                    anchors.left: panSweepAngleLabel.right
                    anchors.top: parent.top
                    text: QGroundControl.hbSettings.value("panSweepAngle", 20)
                    onEditingFinished: {
                        QGroundControl.hbSettings.setValue("panSweepAngle", text);
                    }
                }

                QGCLabel {
                    id: wiredMinAltitudeLabel
                    text : "Wired Min Alt";
                    anchors.left: panSweepAngleLabel.left
                    anchors.baseline: wiredMinAltitudeLabelField.baseline
                }
                QGCTextField {
                    id: wiredMinAltitudeLabelField
                    validator: IntValidator { bottom: 5; top: 2000 }
                    anchors.topMargin: _margins
                    anchors.left: panSweepAngleField.left
                    anchors.top: panSweepAngleField.bottom
                    text: QGroundControl.hbSettings.value("wiredMinAltitude", 5)
                    onEditingFinished: {
                        QGroundControl.hbSettings.setValue("wiredMinAltitude", text);
                    }
                }

                QGCLabel {
                    id: wiredMaxAltitudeLabel
                    text : "Wired Max Alt";
                    anchors.left: panSweepAngleLabel.left
                    anchors.baseline: wiredMaxAltitudeLabelField.baseline
                }
                QGCTextField {
                    id: wiredMaxAltitudeLabelField
                    validator: IntValidator { bottom: 5; top: 2000 }
                    anchors.topMargin: _margins
                    anchors.left: panSweepAngleField.left
                    anchors.top: wiredMinAltitudeLabelField.bottom
                    text: QGroundControl.hbSettings.value("wiredMaxAltitude", 60)
                    onEditingFinished: {
                        QGroundControl.hbSettings.setValue("wiredMaxAltitude", text);
                    }
                }
            } // Rectangle altitude control
      } // QGCFlickable
    } // QGCViewPanel
} // QGCView
