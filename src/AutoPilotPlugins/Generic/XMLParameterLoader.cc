#include "XMLParameterLoader.h"

/// @file
///     @author Pritam Ghanghas <pritam.ghanghas@gmail.com>

bool XMLParameterLoader::_parameterMetaDataLoaded = false;
QMap<QString, FactMetaData*> XMLParameterLoader::_mapParameterName2FactMetaData;

QGC_LOGGING_CATEGORY(XMLParameterLoaderLog, "XMLParameterLoaderLog")


XMLParameterLoader::XMLParameterLoader(AutoPilotPlugin* autopilot, Vehicle* vehicle, QObject* parent)
    : ParameterLoader(autopilot, vehicle, parent)
{

}

/// Converts a string to a typed QVariant
///     @param string String to convert
///     @param type Type for Fact which dictates the QVariant type as well
///     @param convertOk Returned: true: conversion success, false: conversion failure
/// @return Returns the correctly type QVariant
QVariant XMLParameterLoader::_stringToTypedVariant(const QString& string, FactMetaData::ValueType_t type, bool* convertOk)
{
    QVariant var(string);

    int convertTo = QVariant::Int; // keep compiler warning happy
    switch (type) {
        case FactMetaData::valueTypeUint8:
        case FactMetaData::valueTypeUint16:
        case FactMetaData::valueTypeUint32:
            convertTo = QVariant::UInt;
            break;
        case FactMetaData::valueTypeInt8:
        case FactMetaData::valueTypeInt16:
        case FactMetaData::valueTypeInt32:
            convertTo = QVariant::Int;
            break;
        case FactMetaData::valueTypeFloat:
            convertTo = QMetaType::Float;
            break;
        case FactMetaData::valueTypeDouble:
            convertTo = QVariant::Double;
            break;
    }

    *convertOk = var.convert(convertTo);

    return var;
}

/// Load Parameter Fact meta data
///
/// The meta data comes from firmware parameters.xml file.
void XMLParameterLoader::loadParameterFactMetaData(void)
{
    if (_parameterMetaDataLoaded) {
        return;
    }
    _parameterMetaDataLoaded = true;

    qCDebug(XMLParameterLoaderLog) << "Loading parameter fact meta data";

    Q_ASSERT(_mapParameterName2FactMetaData.count() == 0);

    QString parameterFilename = getXMLMetaDataFileName();

    qCDebug(XMLParameterLoaderLog) << "Loading parameter meta data:" << parameterFilename;

    QFile xmlFile(parameterFilename);
    Q_ASSERT(xmlFile.exists());

    bool success = xmlFile.open(QIODevice::ReadOnly);
    Q_UNUSED(success);
    Q_ASSERT(success);

    QXmlStreamReader xml(xmlFile.readAll());
    xmlFile.close();
    if (xml.hasError()) {
        qWarning() << "Badly formed XML" << xml.errorString();
        return;
    }

    QString         factGroup;
    QString         errorString;
    FactMetaData*   metaData = NULL;
    int             xmlState = XmlStateNone;
    bool            badMetaData = true;

    while (!xml.atEnd()) {
        if (xml.isStartElement()) {
            QString elementName = xml.name().toString();

            if (elementName == "parameters") {
                if (xmlState != XmlStateNone) {
                    qWarning() << "Badly formed XML";
                    return;
                }
                xmlState = XmlStateFoundParameters;

            } else if (elementName == "version") {
                if (xmlState != XmlStateFoundParameters) {
                    qWarning() << "Badly formed XML";
                    return;
                }
                xmlState = XmlStateFoundVersion;

                bool convertOk;
                QString strVersion = xml.readElementText();
                int intVersion = strVersion.toInt(&convertOk);
                if (!convertOk) {
                    qWarning() << "Badly formed XML";
                    return;
                }
                if (intVersion <= 2) {
                    // We can't read these old files
                    qDebug() << "Parameter version stamp too old, skipping load. Found:" << intVersion << "Want: 3 File:" << parameterFilename;
                    return;
                }


            } else if (elementName == "group") {
                if (xmlState != XmlStateFoundVersion) {
                    // We didn't get a version stamp, assume older version we can't read
                    qDebug() << "Parameter version stamp not found, skipping load" << parameterFilename;
                    return;
                }
                xmlState = XmlStateFoundGroup;

                if (!xml.attributes().hasAttribute("name")) {
                    qWarning() << "Badly formed XML";
                    return;
                }
                factGroup = xml.attributes().value("name").toString();
                qCDebug(XMLParameterLoaderLog) << "Found group: " << factGroup;

            } else if (elementName == "parameter") {
                if (xmlState != XmlStateFoundGroup) {
                    qWarning() << "Badly formed XML";
                    return;
                }
                xmlState = XmlStateFoundParameter;

                if (!xml.attributes().hasAttribute("name") || !xml.attributes().hasAttribute("type")) {
                    qWarning() << "Badly formed XML";
                    return;
                }

                QString name = xml.attributes().value("name").toString();
                QString type = xml.attributes().value("type").toString();
                QString strDefault = xml.attributes().value("default").toString();

                qCDebug(XMLParameterLoaderLog) << "Found parameter name:" << name << " type:" << type << " default:" << strDefault;

                // Convert type from string to FactMetaData::ValueType_t

                struct String2Type {
                    const char*                 strType;
                    FactMetaData::ValueType_t   type;
                };

                static const struct String2Type rgString2Type[] = {
                    { "FLOAT",  FactMetaData::valueTypeFloat },
                    { "INT32",  FactMetaData::valueTypeInt32 },
                };
                static const size_t crgString2Type = sizeof(rgString2Type) / sizeof(rgString2Type[0]);

                bool found = false;
                FactMetaData::ValueType_t foundType;
                for (size_t i=0; i<crgString2Type; i++) {
                    const struct String2Type* info = &rgString2Type[i];

                    if (type == info->strType) {
                        found = true;
                        foundType = info->type;
                        break;
                    }
                }
                if (!found) {
                    qWarning() << "Parameter meta data with bad type:" << type << " name:" << name;
                    return;
                }

                // Now that we know type we can create meta data object and add it to the system

                metaData = new FactMetaData(foundType);
                Q_CHECK_PTR(metaData);
                if (_mapParameterName2FactMetaData.contains(name)) {
                    // We can't trust the meta dafa since we have dups
                    qCWarning(XMLParameterLoaderLog) << "Duplicate parameter found:" << name;
                    badMetaData = true;
                    // Reset to default meta data
                    _mapParameterName2FactMetaData[name] = metaData;
                } else {
                    _mapParameterName2FactMetaData[name] = metaData;
                    metaData->setName(name);
                    metaData->setGroup(factGroup);

                    if (xml.attributes().hasAttribute("default") && !strDefault.isEmpty()) {
                        QVariant varDefault;

                        if (metaData->convertAndValidate(strDefault, false, varDefault, errorString)) {
                            metaData->setDefaultValue(varDefault);
                        } else {
                            qCWarning(XMLParameterLoaderLog) << "Invalid default value, name:" << name << " type:" << type << " default:" << strDefault << " error:" << errorString;
                        }
                    }
                }

            } else {
                // We should be getting meta data now
                if (xmlState != XmlStateFoundParameter) {
                    qWarning() << "Badly formed XML";
                    return;
                }

                if (!badMetaData) {
                    if (elementName == "short_desc") {
                        Q_ASSERT(metaData);
                        QString text = xml.readElementText();
                        text = text.replace("\n", " ");
                        qCDebug(XMLParameterLoaderLog) << "Short description:" << text;
                        metaData->setShortDescription(text);

                    } else if (elementName == "long_desc") {
                        Q_ASSERT(metaData);
                        QString text = xml.readElementText();
                        text = text.replace("\n", " ");
                        qCDebug(XMLParameterLoaderLog) << "Long description:" << text;
                        metaData->setLongDescription(text);

                    } else if (elementName == "min") {
                        Q_ASSERT(metaData);
                        QString text = xml.readElementText();
                        qCDebug(XMLParameterLoaderLog) << "Min:" << text;

                        QVariant varMin;
                        if (metaData->convertAndValidate(text, true /* convertOnly */, varMin, errorString)) {
                            metaData->setMin(varMin);
                        } else {
                            qCWarning(XMLParameterLoaderLog) << "Invalid min value, name:" << metaData->name() << " type:" << metaData->type() << " min:" << text << " error:" << errorString;
                        }

                    } else if (elementName == "max") {
                        Q_ASSERT(metaData);
                        QString text = xml.readElementText();
                        qCDebug(XMLParameterLoaderLog) << "Max:" << text;

                        QVariant varMax;
                        if (metaData->convertAndValidate(text, true /* convertOnly */, varMax, errorString)) {
                            metaData->setMax(varMax);
                        } else {
                            qCWarning(XMLParameterLoaderLog) << "Invalid max value, name:" << metaData->name() << " type:" << metaData->type() << " max:" << text << " error:" << errorString;
                        }

                    } else if (elementName == "unit") {
                        Q_ASSERT(metaData);
                        QString text = xml.readElementText();
                        qCDebug(XMLParameterLoaderLog) << "Unit:" << text;
                        metaData->setUnits(text);

                    } else {
                        qDebug() << "Unknown element in XML: " << elementName;
                    }
                }
            }
        } else if (xml.isEndElement()) {
            QString elementName = xml.name().toString();

            if (elementName == "parameter") {
                // Done loading this parameter, validate default value
                if (metaData->defaultValueAvailable()) {
                    QVariant var;

                    if (!metaData->convertAndValidate(metaData->defaultValue(), false /* convertOnly */, var, errorString)) {
                        qCWarning(XMLParameterLoaderLog) << "Invalid default value, name:" << metaData->name() << " type:" << metaData->type() << " default:" << metaData->defaultValue() << " error:" << errorString;
                    }
                }

                // Reset for next parameter
                metaData = NULL;
                badMetaData = false;
                xmlState = XmlStateFoundGroup;
            } else if (elementName == "group") {
                xmlState = XmlStateFoundVersion;
            } else if (elementName == "parameters") {
                xmlState = XmlStateFoundParameters;
            }
        }
        xml.readNext();
    }
}

void XMLParameterLoader::clearStaticData(void)
{
    foreach(QString parameterName, _mapParameterName2FactMetaData.keys()) {
        delete _mapParameterName2FactMetaData[parameterName];
    }
    _mapParameterName2FactMetaData.clear();
    _parameterMetaDataLoaded = false;
}

/// Override from FactLoad which connects the meta data to the fact
void XMLParameterLoader::_addMetaDataToFact(Fact* fact)
{
    if (_mapParameterName2FactMetaData.contains(fact->name())) {
        fact->setMetaData(_mapParameterName2FactMetaData[fact->name()]);
    } else {
        // Use generic meta data
        ParameterLoader::_addMetaDataToFact(fact);
    }
}

