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
///     @author Pritam Ghanghas <pritam.ghanghas@gmail.com>

#include "APMParameterLoader.h"
#include "QGCApplication.h"
#include "QGCLoggingCategory.h"

#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDebug>

QGC_LOGGING_CATEGORY(APMParameterLoaderLog, "APMParameterLoaderLog")


APMParameterLoader::APMParameterLoader(AutoPilotPlugin* autopilot, Vehicle* vehicle, QObject* parent) :
    XMLParameterLoader(autopilot, vehicle, parent)
{
    Q_ASSERT(vehicle);
}


QString APMParameterLoader::getXMLMetaDataFileName()
{
    QString parameterFilename;

    // We want unit test builds to always use the resource based meta data to provide repeatable results
    if (!qgcApp()->runningUnitTests()) {
        // First look for meta data that comes from a firmware download. Fall back to resource if not there.
        QSettings settings;
        QDir parameterDir = QFileInfo(settings.fileName()).dir();
        parameterFilename = parameterDir.filePath("APMParameterFactMetaData.xml");
    }
    if (parameterFilename.isEmpty() || !QFile(parameterFilename).exists()) {
        parameterFilename = ":/AutoPilotPlugins/APM/ParameterFactMetaData.xml";
    }

    return parameterFilename;
}
