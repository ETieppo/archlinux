import QtQuick
import qs

Canvas {
    id: root

    property color color: Theme.accent
    property real radius: Theme.wbRadius
    property real thickness: 2

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onColorChanged: requestPaint()

    function rr(ctx, y) {
        const r = radius, w = width, h = height;
        ctx.beginPath();
        ctx.moveTo(r, y);
        ctx.arcTo(w, y, w, y + h, r);
        ctx.arcTo(w, y + h, 0, y + h, r);
        ctx.arcTo(0, y + h, 0, y, r);
        ctx.arcTo(0, y, w, y, r);
        ctx.closePath();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.globalCompositeOperation = "source-over";
        ctx.fillStyle = color;
        rr(ctx, 0);
        ctx.fill();
        ctx.globalCompositeOperation = "destination-out";
        ctx.fillStyle = "black";
        rr(ctx, -thickness);
        ctx.fill();
    }
}
