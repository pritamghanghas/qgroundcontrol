/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick              2.3
import QtQuick.Controls     1.4
import QtQuick.Controls     2.2


import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

SetupPage {
    id:             tuningPage
    pageComponent:  tuningPageComponent

    Component {
        id: tuningPageComponent

        Column {
            width:      availableWidth
            spacing:    _margins

            FactPanelController { id: controller; factPanel: tuningPage.viewPanel }

            QGCPalette { id: palette; colorGroupEnabled: true }

            // Older firmwares use THR_MODE, newer use MOT_THST_HOVER
//            property bool _throttleMidExists: controller.parameterExists(-1, "THR_MID")
//            property string _hoverTuneParam:  _throttleMidExists ? "THR_MID" : "MOT_THST_HOVER"
//            property real _hoverTuneMin:    _throttleMidExists ? 200 : 0
//            property real _hoverTuneMax:    _throttleMidExists ? 800 : 1
//            property real _hoverTuneStep:   _throttleMidExists ? 10 : 0.01

//            readonly property string _maxAngleDesText:
//            readonly property string _angularPIDesText: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance");
            property bool _rcFeelAvailable:     controller.parameterExists(-1, "RC_FEEL")
            property bool _atcInputTCAvailable: controller.parameterExists(-1, "ATC_INPUT_TC")
            property Fact _rcFeel:              controller.getParameterFact(-1, "RC_FEEL", false)
            property Fact _atcInputTC:          controller.getParameterFact(-1, "ATC_INPUT_TC", false)
            property Fact _rateRollP:           controller.getParameterFact(-1, "r.ATC_RAT_RLL_P")
            property Fact _rateRollI:           controller.getParameterFact(-1, "r.ATC_RAT_RLL_I")
            property Fact _ratePitchP:          controller.getParameterFact(-1, "r.ATC_RAT_PIT_P")
            property Fact _ratePitchI:          controller.getParameterFact(-1, "r.ATC_RAT_PIT_I")
            property Fact _rateClimbP:          controller.getParameterFact(-1, "r.PSC_ACCZ_P")
            property Fact _rateClimbI:          controller.getParameterFact(-1, "r.PSC_ACCZ_I")

            property Fact _ch7Opt:  controller.getParameterFact(-1, "CH7_OPT")
            property Fact _ch8Opt:  controller.getParameterFact(-1, "CH8_OPT")
            property Fact _ch9Opt:  controller.getParameterFact(-1, "CH9_OPT")
            property Fact _ch10Opt: controller.getParameterFact(-1, "CH10_OPT")
            property Fact _ch11Opt: controller.getParameterFact(-1, "CH11_OPT")
            property Fact _ch12Opt: controller.getParameterFact(-1, "CH12_OPT")

            readonly property int   _firstOptionChannel:    7
            readonly property int   _lastOptionChannel:     12

            property Fact   _autoTuneAxes:                  controller.getParameterFact(-1, "AUTOTUNE_AXES")
            property int    _autoTuneSwitchChannelIndex:    0
            readonly property int _autoTuneOption:          17

            property real _margins: ScreenTools.defaultFontPixelHeight

            property bool _loadComplete: false

            ExclusiveGroup { id: fenceActionRadioGroup }
            ExclusiveGroup { id: landLoiterRadioGroup }
            ExclusiveGroup { id: returnAltRadioGroup }

            Component.onCompleted: {
                // Qml Sliders have a strange behavior in which they first set Slider::value to some internal
                // setting and then set Slider::value to the bound properties value. If you have an onValueChanged
                // handler which updates your property with the new value, this first value change will trash
                // your bound values. In order to work around this we don't set the values into the Sliders until
                // after Qml load is done. We also don't track value changes until Qml load completes.
//<<<<<<< HEAD

                for (var i=0; i<tuningParams.count; i++) {
                    tuningSliders.itemAt(i).paramSliderValue = controller.getParameterFact(-1, tuningParams.get(i).param).value
//=======
//                rollPitch.value = _rateRollP.value
//                climb.value = _rateClimbP.value
//                if (_rcFeelAvailable) {
//                    rcFeel.value = _rcFeel.value
//                }
//                if (_atcInputTCAvailable) {
//                    atcInputTC.value = _atcInputTC.value
//>>>>>>> upstream/Stable_V3.4
                }
                _loadComplete = true

                calcAutoTuneChannel()
            }

            /// The AutoTune switch is stored in one of the CH#_OPT parameters. We need to loop through those
            /// to find them and setup the ui accordindly.
            function calcAutoTuneChannel() {
                _autoTuneSwitchChannelIndex = 0
                for (var channel=_firstOptionChannel; channel<=_lastOptionChannel; channel++) {
                    var optionFact = controller.getParameterFact(-1, "CH" + channel + "_OPT")
                    if (optionFact.value == _autoTuneOption) {
                        _autoTuneSwitchChannelIndex = channel - _firstOptionChannel + 1
                        break
                    }
                }
            }

            /// We need to clear AutoTune from any previous channel before setting it to a new one
            function setChannelAutoTuneOption(channel) {
                // First clear any previous settings for AutTune
                for (var optionChannel=_firstOptionChannel; optionChannel<=_lastOptionChannel; optionChannel++) {
                    var optionFact = controller.getParameterFact(-1, "CH" + optionChannel + "_OPT")
                    if (optionFact.value == _autoTuneOption) {
                        optionFact.value = 0
                    }
                }

                // Now set the function into the new channel
                if (channel != 0) {
                    var optionFact = controller.getParameterFact(-1, "CH" + channel + "_OPT")
                    optionFact.value = _autoTuneOption
                }
            }

            Connections { target: _ch7Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch8Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch9Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch10Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch11Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch12Opt; onValueChanged: calcAutoTuneChannel() }


            ListModel {
                id: tuningParams

                ListElement { // 0
                    name: qsTr("Throttle Hover")
                    desc: qsTr("How much throttle is needed to maintain a steady hover")
                    param: "MOT_THST_HOVER"
                    min: 0
                    max: 1
                    step: 0.01
                    visiblecat: 0
                }

                ListElement { // 1
                    name: qsTr("Stabilize Roll Sensitivity P Coefficient")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_ANG_RLL_P"
                    min: 3.0
                    max: 12.0
                    step: 0.25
                    visiblecat: 2
                }

                ListElement { // 2
                    name: qsTr("Rate Roll Sensitivity P")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_RAT_RLL_P"
                    min: 0.08
                    max: 0.30
                    step: 0.005
                    visiblecat: 2
                }

                ListElement { // 3
                    name: qsTr("Rate Roll Sensitivity I")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_RAT_RLL_I"
                    min: 0.01
                    max: 0.5
                    step: 0.01
                    visiblecat: 2
                }

                ListElement { // 4
                    name: qsTr("Rate Roll Sensitivity D")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_RAT_RLL_D"
                    min: 0.0
                    max: 0.02
                    step: 0.001
                    visiblecat: 2
                }

                ListElement { // 5
                    name: qsTr("Stabilize Pitch Sensitivity P Coefficient")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_ANG_PIT_P"
                    min: 3.0
                    max: 12.0
                    step: 0.25
                    visiblecat: 1
                }

                ListElement { // 6
                    name: qsTr("Rate Pitch Sensitivity P")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_RAT_PIT_P"
                    min: 0.08
                    max: 0.35
                    step: 0.005
                    visiblecat: 1
                }

                ListElement { // 7
                    name: qsTr("Rate Pitch Sensitivity I")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_RAT_PIT_I"
                    min: 0.01
                    max: 0.6
                    step: 0.01
                    visiblecat: 1
                }

                ListElement { // 8
                    name: qsTr("Rate Pitch Sensitivity D")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_RAT_PIT_D"
                    min: 0.001
                    max: 0.03
                    step: 0.001
                    visiblecat: 1
                }

                ListElement { // 9
                    name: qsTr("Stabilize Yaw Sensitivity P Coefficient")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_ANG_YAW_P"
                    min: 3.0
                    max: 6.0
                    step: 0.1
                    visiblecat: 3
                }

                ListElement { // 10
                    name: qsTr("Rate Yaw Sensitivity P")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_RAT_YAW_P"
                    min: 0.10
                    max: 0.50
                    step: 0.005
                    visiblecat: 3
                }

                ListElement { // 11
                    name: qsTr("Rate Yaw Sensitivity I")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_RAT_YAW_I"
                    min: 0.01
                    max: 0.05
                    step: 0.01
                    visiblecat: 3
                }

                ListElement { // 12
                    name: qsTr("Rate Yaw Sensitivity D")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ATC_RAT_YAW_D"
                    min: 0.00
                    max: 0.02
                    step: 0.001
                    visiblecat: 3
                }

                ListElement { // 13
                    name: qsTr("Climb Sensitivity P")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ACCEL_Z_P"
                    min: 0.500
                    max: 1.500
                    step: 0.05
                    visiblecat: 0
                }

                ListElement { // 14
                    name: qsTr("Climb Sensitivity I")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "ACCEL_Z_I"
                    min: 0.000
                    max: 3.000
                    step: 0.05
                    visiblecat: 0
                }

                ListElement { // 15
                    name: qsTr("RC Feel")
                    desc: qsTr("Maximum angular correction sensitivity, higher for wind jolt resistance")
                    param: "RC_FEEL_RP"
                    min: 0
                    max: 100
                    step: 10
                    visiblecat: 0
                }

                ListElement { // 16
                    name: qsTr("Max bank angle in degrees")
                    desc: qsTr("Maximum angle that copter can take while moving, higher is faster")
                    param: "ANGLE_MAX"
                    min: 10
                    max: 80
                    step: 5
                    visiblecat: 0
                }

                ListElement { // 17
                    name: qsTr("Pitch Trim in radians")
                    desc: qsTr("compensate for autopilot mount/calibration error")
                    param: "AHRS_TRIM_Y"
                    min: -0.1745
                    max:  0.1745
                    step: 0.01
                    visiblecat: 4
                }

                ListElement { // 18
                    name: qsTr("Roll Trim in radians")
                    desc: qsTr("compensate for autopilot mount/calibration error")
                    param: "AHRS_TRIM_X"
                    min: -0.1745
                    max:  0.1745
                    step: 0.01
                    visiblecat: 4
                }

                ListElement { // 19
                    name: qsTr("Yaw Trim in radians")
                    desc: qsTr("compensate for autopilot mount/calibration error")
                    param: "AHRS_TRIM_Z"
                    min: -0.1745
                    max:  0.1745
                    step: 0.01
                    visiblecat: 4
                }
            }

            Flow {
                id:             flowLayout
                anchors.left:   parent.left
                anchors.right:  parent.right
                spacing:        _margins

                Rectangle {
                    height: autoTuneLabel.height + autoTuneRect.height
                    width:  autoTuneRect.width
                    color:  palette.window

                    QGCLabel {
                        id:                 autoTuneLabel
                        text:               qsTr("AutoTune")
                        font.family:        ScreenTools.demiboldFontFamily
                    }

                    Rectangle {
                        id:             autoTuneRect
                        width:          autoTuneColumn.x + autoTuneColumn.width + _margins
                        height:         autoTuneColumn.y + autoTuneColumn.height + _margins
                        anchors.top:    autoTuneLabel.bottom
                        color:          palette.windowShade

                        Column {
                            id:                 autoTuneColumn
                            anchors.margins:    _margins
                            anchors.left:       parent.left
                            anchors.top:        parent.top
                            spacing:            _margins

                            Row {
                                spacing: _margins

                                QGCLabel { text: qsTr("Axes to AutoTune:") }
                                FactBitmask { fact: _autoTuneAxes }
                            }

                            Row {
                                spacing:    _margins

                                QGCLabel {
                                    anchors.baseline:   autoTuneChannelCombo.baseline
                                    text:               qsTr("Channel for AutoTune switch:")
                                }

                                QGCComboBox {
                                    id:             autoTuneChannelCombo
                                    width:          ScreenTools.defaultFontPixelWidth * 14
                                    model:          [qsTr("None"), qsTr("Channel 7"), qsTr("Channel 8"), qsTr("Channel 9"), qsTr("Channel 10"), qsTr("Channel 11"), qsTr("Channel 12") ]
                                    currentIndex:   _autoTuneSwitchChannelIndex

                                    onActivated: {
                                        var channel = index

                                        if (channel > 0) {
                                            channel += 6
                                        }
                                        setChannelAutoTuneOption(channel)
                                    }
                                }
                            }
                        }
                    } // Rectangle - AutoTune
                } // Rectangle - AutoTuneWrap

                Rectangle {
                    height:     inFlightTuneLabel.height + channel6TuningOption.height
                    width:      channel6TuningOption.width
                    color:      palette.window

                    QGCLabel {
                        id:                 inFlightTuneLabel
                        text:               qsTr("In Flight Tuning")
                        font.family:        ScreenTools.demiboldFontFamily
                    }

                    Rectangle {
                        id:             channel6TuningOption
                        width:          channel6TuningOptColumn.width + (_margins * 2)
                        height:         channel6TuningOptColumn.height + ScreenTools.defaultFontPixelHeight
                        anchors.top:    inFlightTuneLabel.bottom
                        color:          qgcPal.windowShade

                        Column {
                            id:                 channel6TuningOptColumn
                            anchors.margins:    ScreenTools.defaultFontPixelWidth
                            anchors.left:       parent.left
                            anchors.top:        parent.top
                            spacing:            ScreenTools.defaultFontPixelHeight

                            Row {
                                spacing: ScreenTools.defaultFontPixelWidth
                                property Fact nullFact: Fact { }

                                QGCLabel {
                                    anchors.baseline:   optCombo.baseline
                                    text:               qsTr("Channel Option 6 (Tuning):")
                                    //color:            controller.channelOptionEnabled[modelData] ? "yellow" : qgcPal.text
                                }

                                FactComboBox {
                                    id:         optCombo
                                    width:      ScreenTools.defaultFontPixelWidth * 15
                                    fact:       controller.getParameterFact(-1, "TUNE")
                                    indexModel: false
                                }
                            }

                            Row {
                                spacing: ScreenTools.defaultFontPixelWidth
                                property Fact nullFact: Fact { }

                                QGCLabel {
                                    anchors.baseline:   tuneMinField.baseline
                                    text:               qsTr("Min:")
                                    //color:            controller.channelOptionEnabled[modelData] ? "yellow" : qgcPal.text
                                }

                                FactTextField {
                                    id:                 tuneMinField
                                    validator:          DoubleValidator {bottom: 0; top: 32767;}
                                    fact:               controller.getParameterFact(-1, "TUNE_LOW")
                                }

                                QGCLabel {
                                    anchors.baseline:   tuneMaxField.baseline
                                    text:               qsTr("Max:")
                                    //color:            controller.channelOptionEnabled[modelData] ? "yellow" : qgcPal.text
                                }

                                FactTextField {
                                    id:                 tuneMaxField
                                    validator:          DoubleValidator {bottom: 0; top: 32767;}
                                    fact:               controller.getParameterFact(-1, "TUNE_HIGH")
                                }
                            }
                        } // Column - Channel 6 Tuning option
                    } // Rectangle - Channel 6 Tuning options
                } // Rectangle - Channel 6 Tuning options wrap
            } // Flow - Tune


            QGCComboBox {
                id:                 tuningTypeBox
                model:              [qsTr("others"), qsTr("Pitch PID"), qsTr("Roll PID"), qsTr("Yaw PID"),  qsTr("Trims")]
                width:              ScreenTools.defaultFontPixelWidth*10
            }

            Rectangle {
                id:                 basicTuningRect
                anchors.left:       parent.left
                anchors.right:      parent.right
                height:             basicTuningColumn.y + basicTuningColumn.height + _margins
                color:              palette.windowShade

                Column {
                    id:                 basicTuningColumn
                    anchors.margins:    _margins
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.top:        parent.top
                    spacing:            _margins

                    Repeater {
                        id: tuningSliders
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        model: tuningParams

                        Rectangle {
                            width: parent.width
                            height: sliderColumn.height
                            visible: visiblecat === tuningTypeBox.currentIndex
//                            color: "red"
                            color:              palette.windowShade
                            property alias paramSliderValue: valueSlider.value

                            Button {
                                id: downButton
                                height: parent.height
                                anchors.left: parent.left
                                text: "dec"
                                autoRepeat: true
                                onClicked: { valueSlider.decrease() }
                            }

                            Column {
                                id: sliderColumn
                                anchors.left:   downButton.right
                                anchors.right:  upButton.left
                                anchors.margins: _margins


                                QGCLabel {
                                    id:         paramName
                                    anchors.margins: _margins
                                    text:       name + " : " + param
                                    font.family:    ScreenTools.demiboldFontFamily
                                }

                                QGCLabel {
                                    id:         paramDesc
                                    anchors.margins: _margins
                                    text:       desc + " : " +  controller.getParameterFact(-1, param).value.toLocaleString(Qt.locale(), 'f', 4)
                                }

                                Slider {
                                    id:                 valueSlider
                                    width: parent.width
                                    from:               min
                                    to:                 max
                                    stepSize:           step
                                    live:               false
                                    enabled:            false
//                                    tickmarksEnabled:   true
                                    property Fact fact: controller.getParameterFact(-1, param)

                                    onValueChanged: {
                                        if (_loadComplete) {
                                            fact.value = value
                                        }
                                    }
                                }

                            } // column

                            Button {
                                id: upButton
                                height: parent.height
                                anchors.right: parent.right
                                autoRepeat: true
                                text: "inc"
                                onClicked: { valueSlider.increase() }
                            }
                        } //row

                    }
                }
                } // Rectangle - Basic tuning
        } // Column
    } // Component
}// SetupView
