TEMPLATE = app

QT += qml quick
SOURCES += main.cpp

target.path = /opt/Qt5_CinematicExperience
qml.files = Qt5_CinematicExperience.qml content
qml.path = /opt/Qt5_CinematicExperience
INSTALLS += target qml
