#ifndef XMLPARAMETERLOADER_H
#define XMLPARAMETERLOADER_H

#include <QObject>
#include <QMap>
#include <QXmlStreamReader>
#include <QLoggingCategory>

#include "ParameterLoader.h"
#include "FactSystem.h"
#include "AutoPilotPlugin.h"
#include "Vehicle.h"

/// @file
///     @author Pritam Ghanghas <pritam.ghanghas@gmail.com>

Q_DECLARE_LOGGING_CATEGORY(XMLParameterLoaderLog)

class XMLParameterLoader : public ParameterLoader
{
public:
    XMLParameterLoader(AutoPilotPlugin* autopilot, Vehicle* vehicle, QObject* parent = NULL);

    /// Override from ParameterLoader
    virtual QString getDefaultComponentIdParam(void) const { return QString("SYS_AUTOSTART"); }

    virtual QString getXMLMetaDataFileName() = 0;

    void loadParameterFactMetaData(void);
    static void clearStaticData(void);

private:
    enum {
        XmlStateNone,
        XmlStateFoundParameters,
        XmlStateFoundVersion,
        XmlStateFoundGroup,
        XmlStateFoundParameter,
        XmlStateDone
    };

    // Overrides from ParameterLoader
    virtual void _addMetaDataToFact(Fact* fact);

    // Class methods
    static QVariant _stringToTypedVariant(const QString& string, FactMetaData::ValueType_t type, bool* convertOk);

private:
    static bool _parameterMetaDataLoaded;
    static QMap<QString, FactMetaData*> _mapParameterName2FactMetaData;
};

#endif // XMLPARAMETERLOADER_H
