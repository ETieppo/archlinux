import QtQuick

Item {
    id: spike

    property real bx: 0
    property real by: 0
    property real len: 0
    property real wid: 30
    property real angle: 0
    property int key: 0
    property real hot: 0
    property bool springy: false
    property real target: 0
    property real vel: 0

    width: wid
    height: len
    x: bx - wid / 2
    y: by - len
    transformOrigin: Item.Bottom
    rotation: angle
    visible: len > 1

    FrameAnimation {
        running: spike.springy
        onTriggered: {
            const dt = Math.min(frameTime, 0.05);
            spike.vel += ((spike.target - spike.len) * 70 - spike.vel * 7) * dt;
            spike.len = Math.max(0, spike.len + spike.vel * dt);
        }
    }

    Image {
        anchors.fill: parent
        source: `lava/spike${spike.key}.png`
        sourceSize: Qt.size(96, 320)
        smooth: true
        opacity: 1 - spike.hot
        visible: opacity > 0
    }
    Image {
        anchors.fill: parent
        source: `lava/spike${spike.key}h.png`
        sourceSize: Qt.size(96, 320)
        smooth: true
        opacity: spike.hot
        visible: opacity > 0
    }
}
