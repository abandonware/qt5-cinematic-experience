QMAKE_LFLAGS += -pie

QT += core

SOURCES += tizenmain.cpp

QMAKE_CLEAN += -r ../tizen-build
tizen_manifest.files = tizen-manifest.xml
tizen_manifest.path = /
icon.files = Qt5_CinematicExperience.png
icon.path = /shared/res/
target.path = /bin

INSTALLS += target tizen_manifest icon


LIBS += -lcapi-appfw-application -lcapi-system-system-settings -ldl -ldlog




