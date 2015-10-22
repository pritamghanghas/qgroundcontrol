/*=====================================================================
 
 QGroundControl Open Source Ground Control Station
 
 (c) 2009 - 2014 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 
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

#include "APMAutoPilotPlugin.h"
#include "APMParameterLoader.h"
#include "AutoPilotPluginManager.h"
#include "UAS.h"

/// @file
///     @brief This is the AutoPilotPlugin implementatin for the MAV_AUTOPILOT_AUTOPILOT_MEGA type.
///     @author Don Gagne <don@thegagnes.com>

APMAutoPilotPlugin::APMAutoPilotPlugin(Vehicle* vehicle, QObject* parent) :
    AutoPilotPlugin(vehicle, parent),
    _parameterFacts(NULL),
    _incorrectParameterVersion(false)
{
    Q_ASSERT(vehicle);
    
    _parameterFacts = new APMParameterLoader(this, vehicle, this);
    Q_CHECK_PTR(_parameterFacts);
    
    connect(_parameterFacts, &APMParameterLoader::parametersReady, this, &APMAutoPilotPlugin::_parametersReadyPreChecks);
    connect(_parameterFacts, &APMParameterLoader::parameterListProgress, this, &APMAutoPilotPlugin::parameterListProgress);

    _parameterFacts->loadParameterFactMetaData();
}

APMAutoPilotPlugin::~APMAutoPilotPlugin()
{
    delete _parameterFacts;
}

void APMAutoPilotPlugin::clearStaticData(void)
{
    APMParameterLoader::clearStaticData();
}

const QVariantList& APMAutoPilotPlugin::vehicleComponents(void)
{
    static QVariantList emptyList;

    return emptyList;
}

Fact* APMAutoPilotPlugin::getRCMode()
{
    static Fact fact(-1, "COM_RC_IN_MODE", FactMetaData::valueTypeInt32);
    fact.setValue("1");
    return &fact;
}

/// This will perform various checks prior to signalling that the plug in ready
void APMAutoPilotPlugin::_parametersReadyPreChecks(bool missingParameters)
{
    _parametersReady = true;
    _missingParameters = missingParameters;
    emit missingParametersChanged(_missingParameters);
    emit parametersReadyChanged(_parametersReady);
}
