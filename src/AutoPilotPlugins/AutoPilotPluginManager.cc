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

/// @file
///     @author Don Gagne <don@thegagnes.com>

#include "AutoPilotPluginManager.h"
#include "APM/APMAutoPilotPlugin.h"
#include "PX4/PX4AutoPilotPlugin.h"
#include "Generic/GenericAutoPilotPlugin.h"
#include <QDebug>

IMPLEMENT_QGC_SINGLETON(AutoPilotPluginManager, AutoPilotPluginManager)

AutoPilotPluginManager::AutoPilotPluginManager(QObject* parent) :
    QGCSingleton(parent)
{

}

AutoPilotPluginManager::~AutoPilotPluginManager()
{
    PX4AutoPilotPlugin::clearStaticData();
    APMAutoPilotPlugin::clearStaticData();
    GenericAutoPilotPlugin::clearStaticData();
}

AutoPilotPlugin* AutoPilotPluginManager::newAutopilotPluginForVehicle(Vehicle* vehicle)
{
    AutoPilotPlugin* autoPilotPlugin = NULL;
    switch(vehicle->firmwareType()) {
        case MAV_AUTOPILOT_ARDUPILOTMEGA:
            autoPilotPlugin = new APMAutoPilotPlugin(vehicle, vehicle);
            qDebug() << "loading apm autopilot plugin";
            break;
        case MAV_AUTOPILOT_PX4:
            autoPilotPlugin = new PX4AutoPilotPlugin(vehicle, vehicle);
            break;
        default:
            autoPilotPlugin = new GenericAutoPilotPlugin(vehicle, vehicle);
        break;
    }
    return autoPilotPlugin;
}
