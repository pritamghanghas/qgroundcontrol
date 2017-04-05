#ifndef HBSETTINGS_H
#define HBSETTINGS_H

#include "QGCToolbox.h"
#include <QVariant>

class HBSettings : public QGCTool
{
    Q_OBJECT
public:
    explicit HBSettings(QGCApplication* app, QGCToolbox* toolbox);

    // Override from QGCTool
    virtual void setToolbox(QGCToolbox *toolbox);

    Q_INVOKABLE QVariant value(const QString & key, const QVariant & defaultValue = QVariant()) const;

signals:
    void valueUpdated(const QString& key, const QVariant& value);

public slots:
    void setValue(const QString & key, const QVariant & value);

private:
};

#endif // HBSETTINGS_H
