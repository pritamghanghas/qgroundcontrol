#include "hbsettings.h"
#include <QSettings>
#include <QtQml>

HBSettings::HBSettings(QGCApplication *app, QGCToolbox *toolbox) : QGCTool(app, toolbox)
{

}

void HBSettings::setToolbox(QGCToolbox *toolbox)
{
    QGCTool::setToolbox(toolbox);

    qmlRegisterUncreatableType<HBSettings> ("QGroundControl", 1, 0, "hbSettings", "Reference only");
}

QVariant HBSettings::value(const QString & key, const QVariant & defaultValue) const
{
    QSettings settings;
    settings.beginGroup("HB");
    QVariant rValue = settings.value(key, defaultValue);
    settings.endGroup();
    return rValue;
}

void HBSettings::setValue(const QString & key, const QVariant & value)
{
    QSettings settings;
    settings.beginGroup("HB");
    settings.setValue(key, value);
    settings.endGroup();
    emit valueUpdated(key, value);
}
