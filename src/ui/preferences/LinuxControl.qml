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

//        anchors.margins: _margins

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
                        text:       "Drone OS"
                        font.family: ScreenTools.demiboldFontFamily
                    }


                    Rectangle {
                        id:                     piControlAction
                        width:                  piControlActionsLayout.width + _margins
                        height:                 piControlActionsLayout.height + _margins
                        color:                  qgcPal.windowShade
                        anchors.margins:        _margins/2

                        Column {
                            id:                piControlActionsLayout
                            spacing:           _margins / 2
                            anchors.margins :  _margins/2
                            anchors.centerIn:  parent

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
                        id:         _apConfLabel
                        text:       "Drone Access Point"
                        font.family: ScreenTools.demiboldFontFamily
                    }


                    Rectangle {
                        id:                     _apConf
                        width:                  _APConfLayout.width + _margins
                        height:                 _APConfLayout.height + _margins
                        color:                  qgcPal.windowShade
                        anchors.margins:        _margins/2

                        Grid {
                            id:                _APConfLayout
                            spacing:           _margins / 2
                            anchors.margins :  _margins/2
                            anchors.centerIn:  parent
                            columns: 2

                            QGCLabel {
                                text: "SSID"
                            }
                            QGCTextField {
                                text: QGroundControl.nodeSelector.currentHostAPDConf()["ssid"];
                                maximumLength:  20
                                onEditingFinished: {
                                    var hostapdConfig = QGroundControl.nodeSelector.currentHostAPDConf();
                                    hostapdConfig["ssid"] = text;
                                    QGroundControl.nodeSelector.setCurrentHostAPDConf(hostapdConfig)
                                }
                            }

                            QGCLabel {
                                text : "Password"
                            }
                            QGCTextField {
                                text: QGroundControl.nodeSelector.currentHostAPDConf()["wpa_passphrase"];
                                maximumLength:  20
                                onEditingFinished: {
                                    var hostapdConfig = QGroundControl.nodeSelector.currentHostAPDConf();
                                    hostapdConfig["wpa_passphrase"] = text;
                                    QGroundControl.nodeSelector.setCurrentHostAPDConf(hostapdConfig)
                                }
                            }
                            QGCLabel {
                                text : "Channel"
                            }
                            QGCTextField {
                                text: QGroundControl.nodeSelector.currentHostAPDConf()["channel"];
                                maximumLength:  2
                                validator:      IntValidator {bottom: 1; top: 14;}
                                onEditingFinished: {
                                    var hostapdConfig = QGroundControl.nodeSelector.currentHostAPDConf();
                                    hostapdConfig["channel"] = text;
                                    QGroundControl.nodeSelector.setCurrentHostAPDConf(hostapdConfig)
                                }
                            }
                        }
                    } // Rectangle - System Control
                } // AP column

                //start wired specific settings in a column
                Column {
                    spacing: _margins / 2
                    visible: false

                    QGCLabel {
                        id:         _wiredConfColumn
                        text:       "Surveillance Settings"
                        font.family: ScreenTools.demiboldFontFamily
                    }


                    Rectangle {
                        id:                     _wiredConf
                        width:                  _wiredConfLayout.width + _margins
                        height:                 _wiredConfLayout.height + _margins
                        color:                  qgcPal.windowShade
                        anchors.margins:        _margins/2

                        Grid {
                            id:                _wiredConfLayout
                            spacing:           _margins / 2
                            anchors.margins :  _margins/2
                            anchors.centerIn:  parent
                            columns: 2

                            QGCLabel {
                                text: "Enable Wire"
                            }

                            QGCCheckBox {
                                id:                 wired
                                text:               " "
                                checked:   QGroundControl.hbSettings.value("enableWire", "false") === "true"
                                onClicked: QGroundControl.hbSettings.setValue("enableWire", checked)
                            }

                            QGCLabel {
                                text: "Sweep Angle (degrees)"
                            }
                            QGCTextField {
                                text: QGroundControl.hbSettings.value("panSweepAngle", 20)
                                maximumLength:  3
                                enabled: wired.checked
                                validator: IntValidator { bottom: 5; top: 160 }
                                onEditingFinished: {
                                    QGroundControl.hbSettings.setValue("panSweepAngle", text);
                                }
                            }

                            QGCLabel {
                                text : "sweep speed (degree/s)"
                            }
                            QGCTextField {
                                validator: IntValidator { bottom: 1; top: 10 }
                                maximumLength: 2
                                enabled: wired.checked
                                text: QGroundControl.hbSettings.value("panSweepSpeed", 5)
                                onEditingFinished: {
                                    QGroundControl.hbSettings.setValue("panSweepSpeed", text);
                                }
                            }


                            QGCLabel {
                                text : "Min Alt"
                            }
                            QGCTextField {
                                text: QGroundControl.hbSettings.value("wiredMinAltitude", 5)
                                maximumLength:  4
                                enabled: wired.checked
                                validator: IntValidator { bottom: 5; top: 2000 }
                                onEditingFinished: {
                                    QGroundControl.hbSettings.setValue("wiredMinAltitude", text);
                                }
                            }

                            QGCLabel {
                                text : "Max Alt"
                            }
                            QGCTextField {
                                text: QGroundControl.hbSettings.value("wiredMaxAltitude", 60)
                                maximumLength: 4
                                enabled: wired.checked
                                validator: IntValidator { bottom: 5; top: 2000 }
                                onEditingFinished: {
                                    QGroundControl.hbSettings.setValue("wiredMaxAltitude", text);
                                }
                            }
                        }
                    } // Rectangle - Wired conf
                } // wired column

                //start scout column
                Column {
                    spacing: _margins / 2
                    visible: false

                    QGCLabel {
                        id:         _scoutConfColumn
                        text:       "Scout Settings"
                        font.family: ScreenTools.demiboldFontFamily
                    }


                    Rectangle {
                        id:                     _scoutConf
                        width:                  _scoutConfLayout.width + _margins
                        height:                 _scoutConfLayout.height + _margins
                        color:                  qgcPal.windowShade
                        anchors.margins:        _margins/2

                        Grid {
                            id:                _scoutConfLayout
                            spacing:           _margins / 2
                            anchors.margins :  _margins/2
                            anchors.centerIn:  parent
                            columns: 2

                            QGCLabel {
                                text: qsTr("DMZ Breach Mode")
                            }
                            QGCCheckBox {
                                id:                 scoutMode
                                text:               " "
                                checked:    QGroundControl.hbSettings.value("scoutMode", "false") === "true"
                                onClicked:  QGroundControl.hbSettings.setValue("scoutMode", checked)
                            }


                            QGCLabel {
                                text : "Scout Alt"
                            }
                            QGCTextField {
                                validator: IntValidator { bottom: 1; top: 100 }
                                maximumLength: 3
                                enabled: scoutMode.checked
                                text: QGroundControl.hbSettings.value("scoutAltitude", 60)
                                onEditingFinished: {
                                    QGroundControl.hbSettings.setValue("scoutAltitude", text);
                                }
                            }
                        }
                    } // Rectangle - scout conf
                } // scout column

                Column {
                    spacing: _margins / 2

                    QGCLabel {
                        id:         _otherSettings
                        text:       "Other Settings"
                        font.family: ScreenTools.demiboldFontFamily
                    }

                    QGCCheckBox {
                        id:                 unsafeModes
                        text:               "Enable unsafe flight modes"
                        checked:   QGroundControl.hbSettings.value("unsafeModes", "true") === "true"
                        onClicked: QGroundControl.hbSettings.setValue("unsafeModes", checked)
                    }
                }

            } // flow
        } // QGCFlickable

    } // QGCViewPanel
} // QGCView
