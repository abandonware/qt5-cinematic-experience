TEMPLATE = app

QT += qml quick
SOURCES += main.cpp

host_build {
    target.path = /opt/Qt5_CinematicExperience
    qml.files = Qt5_CinematicExperience.qml content
    qml.path = /opt/Qt5_CinematicExperience
    INSTALLS += target qml
} else {
    RESOURCES += qml.rc \
    data.qrc
}

tizen:include(tizen/tizen.pri)
