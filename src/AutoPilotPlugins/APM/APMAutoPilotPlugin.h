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

#ifndef APMAUTOPILOTPLUGIN_H
#define APMAUTOPILOTPLUGIN_H

#include "AutoPilotPlugin.h"
#include "APMParameterLoader.h"
#include "Vehicle.h"

#include <QImage>

/// @file
///     @brief This is the PX4 specific implementation of the AutoPilot class.
///     @author Don Gagne <don@thegagnes.com>

class APMAutoPilotPlugin : public AutoPilotPlugin
{
    Q_OBJECT

public:
    APMAutoPilotPlugin(Vehicle* vehicle, QObject* parent = NULL);
    ~APMAutoPilotPlugin();

    // Overrides from AutoPilotPlugin
    virtual const QVariantList& vehicleComponents(void);

    static void clearStaticData(void);

    virtual Fact* getRCMode();

private slots:
    void _parametersReadyPreChecks(bool missingParameters);
    
private:
	// Overrides from AutoPilotPlugin
	virtual ParameterLoader* _getParameterLoader(void) { return _parameterFacts; }
	
    APMParameterLoader*     _parameterFacts;
    bool                    _incorrectParameterVersion; ///< true: parameter version incorrect, setup not allowed
};

#endif
