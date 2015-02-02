import QtQuick 2.0
import "content"

Item {
    id: mainWindow

    anchors.fill: parent

    QtObject {
        id: settings
        // These are used to scale fonts according to screen size
        property real _scaler: 300 + mainWindow.width * mainWindow.height * 0.00015
        property int fontXS: _scaler * 0.032
        property int fontS: _scaler * 0.040
        property int fontM: _scaler * 0.046
        property int fontMM: _scaler * 0.064
        property int fontL: _scaler * 0.100
        // Settings
        property bool showFogParticles: true
        property bool showShootingStarParticles: true
        property bool showLighting: true
        property bool showColors: true
    }

    MainView {
        id: mainView
    }

    InfoView {
        id: infoView
    }

    DetailsView {
        id: detailsView
    }

    MoviesModel {
        id: moviesModel
    }

    FpsItem {
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.leftMargin: 8
    }
}
