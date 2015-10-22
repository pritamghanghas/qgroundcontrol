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

#ifndef PX4PARAMETERLOADER_H
#define PX4PARAMETERLOADER_H

#include <QObject>
#include <QMap>
#include <QXmlStreamReader>
#include <QLoggingCategory>

#include "Generic/XMLParameterLoader.h"
#include "FactSystem.h"
#include "AutoPilotPlugin.h"
#include "Vehicle.h"

/// @file
///     @author Don Gagne <don@thegagnes.com>

Q_DECLARE_LOGGING_CATEGORY(PX4ParameterLoaderLog)

/// Collection of Parameter Facts for PX4 AutoPilot

class PX4ParameterLoader : public XMLParameterLoader
{
    Q_OBJECT
    
public:
    /// @param uas Uas which this set of facts is associated with
    PX4ParameterLoader(AutoPilotPlugin* autopilot, Vehicle* vehicle, QObject* parent = NULL);

    virtual QString getXMLMetaDataFileName();
    
private:
};

#endif
