VideoEnabled {

INCLUDEPATH += \
    src/hb

HEADERS += \
    src/hb/pidiscoverer.h \
    src/hb/nodeselector.h \
    src/hb/thermalimageprovider.h \
    src/hb/mjpegimagegrabber.h

SOURCES += \
    src/hb/pidiscoverer.cpp \
    src/hb/nodeselector.cpp \
    src/hb/thermalimageprovider.cpp \
    src/hb/mjpegimagegrabber.cpp
}

HEADERS += \
    $$PWD/hbsettings.h

SOURCES += \
    $$PWD/hbsettings.cpp
