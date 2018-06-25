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
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0

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

    property var _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle

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
                                id: shutdownButton
                                text:       "Shutdown Flight Computer"
                                onClicked: confirmAction(confirmShutdown)
                            }
                            QGCButton {
                                text:       "Restart Flight Computer"
                                width: shutdownButton.width
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

                Column {
                    spacing: _margins / 2

                    QGCLabel {
                        id:         _virtualJoystickSettings
                        text:       "Virtual Joystick Settings"
                        font.family: ScreenTools.demiboldFontFamily
                    }

                    FactCheckBox {
                        text:       qsTr("Virtual Joystick has Spring Loaded Throttle")
                        visible:    _virtualJoystickSpringLoaded.visible
                        fact:       _virtualJoystickSpringLoaded

                        property Fact _virtualJoystickSpringLoaded: QGroundControl.settingsManager.appSettings.virtualJoystickSpringLoaded
                    }

                    ListModel {
                        id: channelOpts

                        ListElement { name: "disabled" }
                        ListElement { name: "dial" }
                        ListElement { name: "switch" }
                    }

                    Grid {
                        width:      parent.width
                        spacing:    ScreenTools.defaultFontPixelWidth
                        columns:    2

                        QGCLabel {
                            id:                 joystickModeLabel
                            text:               qsTr("Joystick mode:")
                        }

                        QGCComboBox {
                            id:             joystickModeCombo
                            currentIndex:   _activeVehicle.joystickMode
                            width:          ScreenTools.defaultFontPixelWidth * 20
                            model:          _activeVehicle.joystickModes

                            onActivated: _activeVehicle.joystickMode = index
                        }



                            QGCLabel {
                                text: "channel6:"
                            }
                            QGCComboBox {
                                id:             channel6combo
                                currentIndex:   QGroundControl.hbSettings.value("vchannel6", 0)
                                width:          ScreenTools.defaultFontPixelWidth * 20
                                model:          channelOpts

                                onActivated: QGroundControl.hbSettings.setValue("vchannel6", currentIndex)
                            }


                            QGCLabel {
                                text : "channel7:"
                            }
                            QGCComboBox {
                                id:             channel7combo
                                currentIndex:   QGroundControl.hbSettings.value("vchannel7", 0)
                                width:          ScreenTools.defaultFontPixelWidth * 20
                                model:          channelOpts

                                onActivated: QGroundControl.hbSettings.setValue("vchannel7", currentIndex)
                            }


                            QGCLabel {
                                text : "channel8:"
                            }
                            QGCComboBox {
                                id:             channel8combo
                                currentIndex:   QGroundControl.hbSettings.value("vchannel8", 0)
                                width:          ScreenTools.defaultFontPixelWidth * 20
                                model:          channelOpts

                                onActivated: QGroundControl.hbSettings.setValue("vchannel8", currentIndex)
                            }
                        }
                } //virtual joystick settings

            } // flow
        } // QGCFlickable

    } // QGCViewPanel
} // QGCView
