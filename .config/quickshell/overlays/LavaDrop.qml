import QtQuick

// one soft sprite in the launcher's metaball field
Item {
    id: drop

    property real cx: 0
    property real cy: 0
    property real r: 40 // visual radius once thresholded
    property int hue: 0 // 0..3, palette slot
    property real hot: 0 // 1 = selected

    width: r * 3.7
    height: width
    x: cx - width / 2
    y: cy - height / 2
    visible: r > 0.5

    Image {
        anchors.fill: parent
        source: `lava/drop${drop.hue}.png`
        sourceSize: Qt.size(256, 256)
        smooth: true
        opacity: 1 - drop.hot
        visible: opacity > 0
    }
    Image {
        anchors.fill: parent
        source: `lava/drop${drop.hue}h.png`
        sourceSize: Qt.size(256, 256)
        smooth: true
        opacity: drop.hot
        visible: opacity > 0
    }
}
