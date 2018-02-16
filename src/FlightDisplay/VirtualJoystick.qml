/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick 2.3

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.Vehicle       1.0

Item {
    //property bool useLightColors - Must be passed in from loaded

    // hack to ensure that joystick is in good position
    // even when it has not been touched yet.
    property var firstTrigger: 0

    Timer {
        interval:   40  // 25Hz, same as real joystick rate
        running:    QGroundControl.settingsManager.appSettings.virtualJoystick.value && _activeVehicle
        repeat:     true
        onTriggered: {
            checkInitialPlacement()
            if (_activeVehicle) {
                _activeVehicle.virtualTabletJoystickValue(rightStick.xAxis, rightStick.yAxis, leftStick.xAxis, leftStick.yAxis)
            }
        }
    }

    function checkInitialPlacement()
    {
        if (firstTrigger == 0) {

            firstTrigger = 1

            leftStick.reCenter()
            leftStick.updateXAxis()
            leftStick.updateYAxis()

            rightStick.reCenter()
            rightStick.updateXAxis()
            rightStick.updateYAxis()
        }
    }

    JoystickThumbPad {
        id:                     leftStick
        anchors.leftMargin:     xPositionDelta
        anchors.bottomMargin:   -yPositionDelta
        anchors.left:           parent.left
        anchors.bottom:         parent.bottom
        width:                  parent.height
        height:                 parent.height
        yAxisThrottle:          true
        yAxisSpringLoaded:      QGroundControl.settingsManager.appSettings.virtualJoystickSpringLoaded.value
        lightColors:            useLightColors
    }

    JoystickThumbPad {
        id:                     rightStick
        anchors.rightMargin:    -xPositionDelta
        anchors.bottomMargin:   -yPositionDelta
        anchors.right:          parent.right
        anchors.bottom:         parent.bottom
        width:                  parent.height
        height:                 parent.height
        lightColors:            useLightColors
    }
}
