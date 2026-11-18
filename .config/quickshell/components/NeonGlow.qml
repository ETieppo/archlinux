import QtQuick
import QtQuick.Effects
import qs

MultiEffect {
    property color glowColor: Theme.accent
    property real strength: 0.8

    shadowEnabled: true
    shadowColor: glowColor
    shadowOpacity: strength
    shadowBlur: 1
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    blurMax: 24
    autoPaddingEnabled: true
}
