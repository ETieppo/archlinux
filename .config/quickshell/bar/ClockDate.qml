import QtQuick
import QtQuick.Layouts
import qs

RowLayout {
  spacing: 0

  WbModule {
    minChars: 5
    padL: 19
    padR: 16
    text: Qt.formatTime(BarKit.now, "HH:mm")
    tip: `<b>Standard Time</b>: ${Qt.formatTime(BarKit.now, "hh:mm AP").toLowerCase()}`
  }
  WbModule {
    id: datePill
    minChars: 8
    padL: 19
    padR: 16
    text: "󰸗 " + Qt.formatDate(BarKit.now, "dd-MM")

    CalendarPopup {
      target: datePill
      visible: datePill.hovered
    }
  }
}
