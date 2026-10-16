import QtQuick
import qs

Item {
  id: root

  property bool vertical: true
  property real thickness: 6
  property real knob: thickness * 2.6

  implicitWidth: vertical ? thickness : 200
  implicitHeight: vertical ? 60 : thickness

  readonly property real p: Sky.progress
  readonly property color here: Sky.body

  component SkyGradient: Rectangle {
    radius: root.thickness / 2
    gradient: Gradient {
      orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
      GradientStop { position: Sky.stops[0][0]; color: Sky.stops[0][1] }
      GradientStop { position: Sky.stops[1][0]; color: Sky.stops[1][1] }
      GradientStop { position: Sky.stops[2][0]; color: Sky.stops[2][1] }
      GradientStop { position: Sky.stops[3][0]; color: Sky.stops[3][1] }
      GradientStop { position: Sky.stops[4][0]; color: Sky.stops[4][1] }
      GradientStop { position: Sky.stops[5][0]; color: Sky.stops[5][1] }
      GradientStop { position: Sky.stops[6][0]; color: Sky.stops[6][1] }
      GradientStop { position: Sky.stops[7][0]; color: Sky.stops[7][1] }
      GradientStop { position: Sky.stops[8][0]; color: Sky.stops[8][1] }
    }
  }

  SkyGradient {
    anchors.fill: parent
    opacity: 0.22
  }

  Item {
    width: root.vertical ? root.width : root.width * root.p
    height: root.vertical ? root.height * root.p : root.height
    clip: true
    SkyGradient {
      width: root.width
      height: root.height
    }
  }

  Repeater {
    model: [Sky.sunrise, Sky.sunset]
    Rectangle {
      required property real modelData
      x: root.vertical ? -2 : root.width * modelData - 1
      y: root.vertical ? root.height * modelData - 1 : -2
      width: root.vertical ? root.width + 4 : 2
      height: root.vertical ? 2 : root.height + 4
      radius: 1
      color: Theme.bgSolid
      opacity: 0.8
    }
  }

  Item {
    x: (root.vertical ? root.width / 2 : root.width * root.p) - width / 2
    y: (root.vertical ? root.height * root.p : root.height / 2) - height / 2
    width: root.knob
    height: width

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: root.here
      border.width: 1.5
      border.color: Theme.bgSolid
    }
  }
}
