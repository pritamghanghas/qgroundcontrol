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

#include "SetupViewTest.h"
#include "MockLink.h"
#include "QGCMessageBox.h"
#include "MultiVehicleManager.h"

UT_REGISTER_TEST(SetupViewTest)

void SetupViewTest::_clickThrough_test(void)
{
    _connectMockLink();
    
    AutoPilotPlugin* autopilot = qgcApp()->toolbox()->multiVehicleManager()->activeVehicle()->autopilotPlugin();
    Q_ASSERT(autopilot);

    _createMainWindow();

    // Switch to the Setup view
    _mainWindow->showSetupView();
    QTest::qWait(1000);
    
    // Click through fixed buttons
    qDebug() << "Showing firmware";
    _mainWindow->showSetupFirmware();
    QTest::qWait(1000);
    qDebug() << "Showing parameters";
    _mainWindow->showSetupParameters();
    QTest::qWait(1000);
    qDebug() << "Showing summary";
    _mainWindow->showSetupSummary();
    QTest::qWait(1000);
    
    const QVariantList& components = autopilot->vehicleComponents();
    foreach(QVariant varComponent, components) {
        VehicleComponent* component = qobject_cast<VehicleComponent*>(qvariant_cast<QObject *>(varComponent));
        qDebug() << "Showing" << component->name();
        _mainWindow->showSetupVehicleComponent(component);
        QTest::qWait(1000);
    }

    // On MainWindow close we should get a message box telling the user to disconnect first.
    
    setExpectedMessageBox(QGCMessageBox::Yes);
    
    _closeMainWindow();
    checkExpectedMessageBox();
}
