import QtQuick
import qs

Canvas {
    id: root

    property real value: 0
    property color color: Theme.accent
    property color track: Theme.surface2
    property real thickness: 3

    Behavior on value { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    onValueChanged: requestPaint()
    onColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) / 2 - thickness / 2 - 1;
        const cx = width / 2, cy = height / 2;
        ctx.lineWidth = thickness;
        ctx.lineCap = "round";
        ctx.strokeStyle = track;
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
        ctx.stroke();
        const v = Math.max(0, Math.min(1, value));
        if (v > 0.001) {
            ctx.strokeStyle = color;
            ctx.beginPath();
            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * v);
            ctx.stroke();
        }
    }
}
