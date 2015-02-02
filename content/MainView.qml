import QtQuick 2.0
import QtQuick.Particles 2.0
import QtGraphicalEffects 1.0

Item {
    id: root

    // Set this to blur the mainView when showing something on top of it
    property real blurAmount: 0

    // Updates the blur shader source, best called right before adding blurAmount
    function scheduleUpdate() {
        mainContentSource.scheduleUpdate();
    }

    anchors.fill: parent

    // Update blur shader source when width/height changes
    onHeightChanged: {
        root.scheduleUpdate();
    }
    onWidthChanged: {
        root.scheduleUpdate();
    }

    Item {
        id: mainViewArea
        anchors.fill: parent

        Background {
            id: background
        }

        ListView {
            id: listView

            property real globalLightPosX: lightImage.x / root.width
            property real globalLightPosY: lightImage.y / root.height

            // Normal-mapped cover shared among delegates
            ShaderEffectSource {
                id: coverNmapSource
                sourceItem: Image { source: "images/cover_nmap.png" }
                hideSource: true
                visible: false
            }

            anchors.fill: parent
            spacing: -60
            model: moviesModel
            delegate: DelegateItem {
                name: model.name
            }
            highlightFollowsCurrentItem: true
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 400
            preferredHighlightBegin: root.height * 0.5 - 140
            preferredHighlightEnd: root.height * 0.5 - 140
            cacheBuffer: 4000
        }

        Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -40
            anchors.horizontalCenter: parent.horizontalCenter
            width: 180 + parent.width * 0.25
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: listView.currentIndex+1 + ". " + listView.currentItem.name
            color: "#ffffff"
            style: Text.Outline
            styleColor: "#b0a030"
            font.pixelSize: settings.fontL
            Behavior on text {
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: titleText; property: "opacity"; duration: 100; to: 0; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: titleText; property: "scale"; duration: 100; to: 0.6; easing.type: Easing.InOutQuad }
                    }
                    PropertyAction { target: titleText; property: "text" }
                    ParallelAnimation {
                        NumberAnimation { target: titleText; property: "opacity"; duration: 100; to: 1; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: titleText; property: "scale"; duration: 100; to: 1; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }

        Image {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32
            anchors.horizontalCenter: parent.horizontalCenter
            source: "images/qt_logo.png"
            opacity: listView.atYEnd
            Behavior on opacity {
                NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
            }
        }

        // Shooting star + animation + particles
        AnimatedSprite {
            id: lightImage
            width: 128
            height: 128
            frameWidth: 128
            frameHeight: 128
            frameCount: 16
            frameRate: 15
            source: "images/planet_sprite.png"
            interpolate: true
            loops: Animation.Infinite
            visible: settings.showLighting || settings.showShootingStarParticles
            running: !detailsView.isShown && !infoView.isShown && (settings.showLighting || settings.showShootingStarParticles)
        }

        PathAnimation {
            target: lightImage
            duration: 5000
            orientation: PathAnimation.RightFirst
            anchorPoint: Qt.point(lightImage.width/2, lightImage.height/2)
            running: true
            paused: detailsView.isShown || infoView.isShown || (!settings.showLighting && !settings.showShootingStarParticles)
            loops: Animation.Infinite
            path: Path {
                id: lightAnimPath
                startX: root.width*0.4; startY: root.height*0.3
                PathCurve { x: root.width*0.8; y: root.height*0.2 }
                PathCurve { x: root.width*0.8; y: root.height*0.7 }
                PathCurve { x: root.width*0.1; y: root.height*0.6 }
                PathCurve { x: root.width*0.4; y: root.height*0.3 }
            }
        }

        ParticleSystem {
            anchors.fill: parent
            paused: detailsView.isShown || infoView.isShown

            // Shooting star particles
            ImageParticle {
                source: "images/particle.png"
                color: "#ffefaf"
                colorVariation: settings.showColors ? 1.0 : 0.1
                alpha: 0
            }
            Emitter {
                id: shootingStarEmitter
                emitRate: settings.showShootingStarParticles ? 100 : 0
                lifeSpan: 2000
                x: lightImage.x + lightImage.width/2
                y: lightImage.y + lightImage.height/2
                velocity: PointDirection {xVariation: 8; yVariation: 8;}
                acceleration: PointDirection {xVariation: 12; yVariation: 12;}
                size: 32
                sizeVariation: 16
            }
            Emitter {
                id: shootingStarBurst
                emitRate: 0
                lifeSpan: 2000
                x: lightImage.x + lightImage.width/2
                y: lightImage.y + lightImage.height/2
                velocity: PointDirection {xVariation: 60; yVariation: 60;}
                acceleration: PointDirection {xVariation: 40; yVariation: 40;}
                size: 24
                sizeVariation: 16
            }

            // Dust/Smoke particles
            ImageParticle {
                groups: ["smoke"]
                source: "images/smoke.png"
                color: "#ffffff"
                alpha: 0.9
                opacity: 0.8
                colorVariation: settings.showColors ? 0.9 : 0.0
                rotationVariation: 180
            }
            Emitter {
                y: root.height * 0.85
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200 + parent.width * 0.1
                height: root.height * 0.3
                emitRate: settings.showFogParticles ? 8 : 0
                lifeSpan: 2000
                lifeSpanVariation: 1000
                group: "smoke"
                size: 192
                sizeVariation: 64
                acceleration: PointDirection { y: -80; xVariation: 20 }
            }
            Emitter {
                y: root.height * 0.9
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200 + parent.width * 0.1
                height: root.height * 0.2
                emitRate: settings.showFogParticles ? 10 : 0
                lifeSpan: 2000
                group: "smoke"
                size: 192
                sizeVariation: 64
                acceleration: PointDirection { y: -20; xVariation: 40 }
            }
            Turbulence {
                groups: ["smoke"]
                width: parent.width
                height: parent.height * 0.8
                strength: 60
            }
        }

        SettingsView {
            id: settingsView
        }
    }

    FastBlur {
        anchors.fill: mainViewArea
        radius: root.blurAmount
        visible: root.blurAmount
        source: ShaderEffectSource {
            id: mainContentSource
            anchors.fill: parent
            sourceItem: mainViewArea
            hideSource: false
            live: false
            visible: root.blurAmount
        }
    }
}
