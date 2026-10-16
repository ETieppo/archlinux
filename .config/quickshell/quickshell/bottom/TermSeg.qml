import QtQuick
import Quickshell
import qs
import qs.components

Seg {
    id: root

    readonly property var job: Term.job
    readonly property var last: Term.last
    readonly property real age: last ? Term.now - last.at : Infinity
    readonly property color result: !last ? Theme.muted : last.status === 0 ? Theme.green : last.status === 130 ? Theme.yellow : Theme.red

    function short(cmd) {
        return cmd.replace(/\s+/g, " ").trim();
    }

    progress: job ? (Term.progress >= 0 ? Term.progress : 0) : last && age < 600000 ? 1 : 0
    busy: job !== null && (Term.progress < 0 || Term.progress >= 0.97)
    tint: job ? Theme.accent : result
    fillOpacity: job ? 1 : age < 8000 ? 1 : 0.3
    tip: job ? `${job.cmd}\n${job.cwd.replace(Quickshell.env("HOME"), "~")}` + (job.est > 0 ? `\nestimated ${Term.fmt(job.est)} from previous runs` : "\nfirst run, no estimate yet") + (Term.live.length > 1 ? `\n+${Term.live.length - 1} running in parallel` : "") : last ? `${last.cmd}\n${last.status === 0 ? "finished" : last.status === 130 ? "interrupted" : `exit ${last.status}`} in ${Term.fmt(last.dur)}` : "Terminal processes show up here"

    Icon {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        text: "󰆍"
        font.pixelSize: 14
        color: root.job ? Theme.accent : root.last && root.age < 600000 ? root.result : Theme.muted
        Behavior on color { ColorAnimation { duration: 400 } }
    }

    Label {
        anchors.left: glyph.right
        anchors.leftMargin: 8
        anchors.right: meta.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        font.pixelSize: 12
        font.bold: root.job !== null
        color: root.job ? Theme.fg : Theme.dim
        text: root.job ? root.short(root.job.cmd) : root.last && root.age < 600000 ? root.short(root.last.cmd) : "terminal idle"
    }

    Label {
        id: meta
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 11
        color: root.job ? Theme.accent : Theme.dim
        text: root.job ? (Term.live.length > 1 ? `+${Term.live.length - 1}  ` : "") + Term.fmt(Term.elapsed) + (root.job.est > 0 ? ` / ${Term.fmt(root.job.est)}` : "") : root.last && root.age < 600000 ? Term.fmt(root.last.dur) : ""
    }
}
