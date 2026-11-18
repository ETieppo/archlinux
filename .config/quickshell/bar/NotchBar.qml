import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components

PanelWindow {
  id: bar

  required property ShellScreen modelData

  readonly property real pixelRatio: Hyprland.monitorFor(modelData)?.scale || modelData.devicePixelRatio || 1
  readonly property real stripHeight: Hardware.notchStripPhysicalHeight > 0 ? Math.round(Hardware.notchStripPhysicalHeight / pixelRatio) : Theme.wbHeight + 2 * Theme.gap
  readonly property real notchWidth: Hardware.notchPhysicalWidth / pixelRatio
  readonly property real notchHeight: Hardware.notchPhysicalHeight / pixelRatio
  readonly property bool hasNotch: notchWidth > 0
  readonly property real notchClearance: 14
  readonly property real notchHug: 0
  readonly property real shoulderDepth: hasNotch ? 6 : 0
  readonly property real cornerRadius: 12
  readonly property real topFlare: 6
  readonly property real sideHeight: stripHeight - shoulderDepth
  readonly property real glowSpace: 8
  readonly property real lineWidth: 1.5
  readonly property real fadeStartRatio: 0.1
  readonly property real leftInset: Theme.sideWidth
  readonly property real screenCenter: modelData.width / 2 - leftInset
  readonly property real notchLeft: screenCenter - notchWidth / 2
  readonly property real notchRight: screenCenter + notchWidth / 2
  readonly property real contourLeft: notchLeft - notchHug
  readonly property real contourRight: notchRight + notchHug
  readonly property real leftWingWidth: (hasNotch ? contourLeft - topFlare - notchClearance : screenCenter) - 2 * Theme.gap
  readonly property real rightWingWidth: width - (hasNotch ? contourRight + topFlare + notchClearance : screenCenter) - 2 * Theme.gap

  screen: modelData
  color: "transparent"
  implicitHeight: stripHeight + glowSpace
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: true
    left: true
    right: true
  }
  margins.left: leftInset

  mask: Region {
    item: stripArea
  }

  PanelWindow {
    screen: bar.modelData
    color: "transparent"
    implicitHeight: 1
    exclusiveZone: bar.stripHeight
    mask: Region {}

    anchors {
      top: true
      left: true
      right: true
    }
  }

  function notchOutline(ctx, inset, top) {
    const left = bar.contourLeft + inset, right = bar.contourRight - inset, bottom = bar.notchHeight - inset, r = bar.cornerRadius, flare = bar.topFlare;
    ctx.lineTo(left - flare, top);
    ctx.quadraticCurveTo(left, top, left, top + flare);
    ctx.lineTo(left, bottom - r);
    ctx.arcTo(left, bottom, left + r, bottom, r);
    ctx.lineTo(right - r, bottom);
    ctx.arcTo(right, bottom, right, bottom - r, r);
    ctx.lineTo(right, top + flare);
    ctx.quadraticCurveTo(right, top, right + flare, top);
  }

  onNotchWidthChanged: repaint()
  onNotchHeightChanged: repaint()

  function repaint() {
    notchNeon.requestPaint();
  }

  function accentRgba(alpha) {
    return `rgba(${Math.round(Theme.accent.r * 255)}, ${Math.round(Theme.accent.g * 255)}, ${Math.round(Theme.accent.b * 255)}, ${alpha})`;
  }

  Item {
    id: stripArea
    width: parent.width
    height: bar.stripHeight
  }

  Canvas {
    id: notchNeon
    anchors.fill: parent
    visible: bar.hasNotch
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    layer.enabled: true
    layer.effect: NeonGlow {
      strength: 0.6
    }
    onPaint: {
      const ctx = getContext("2d");
      const top = bar.lineWidth / 2;
      const leftFadeStart = bar.contourLeft * (1 - bar.fadeStartRatio) / bar.width;
      const rightFadeStart = (bar.contourRight + (bar.width - bar.contourRight) * bar.fadeStartRatio) / bar.width;
      const fade = ctx.createLinearGradient(0, 0, bar.width, 0);
      ctx.reset();
      for (const [position, alpha] of [[0, 0], [0.3, 0.06], [0.55, 0.22], [0.8, 0.5], [1, 0.8]]) {
        fade.addColorStop(leftFadeStart * position, bar.accentRgba(alpha));
        fade.addColorStop(1 - (1 - rightFadeStart) * position, bar.accentRgba(alpha));
      }
      ctx.beginPath();
      ctx.moveTo(0, top);
      bar.notchOutline(ctx, -bar.lineWidth / 2, top);
      ctx.lineTo(bar.width, top);
      ctx.strokeStyle = fade;
      ctx.lineWidth = bar.lineWidth;
      ctx.stroke();
    }
  }

  Item {
    x: Theme.gap
    width: bar.leftWingWidth
    height: bar.sideHeight
    clip: true

    RowLayout {
      anchors.verticalCenter: parent.verticalCenter
      height: Theme.wbHeight
      spacing: 0

      DistroMark {}
      AppStrip {}
      SystemStats {}
    }
  }

  Item {
    x: bar.width - Theme.gap - width
    width: bar.rightWingWidth
    height: bar.sideHeight
    clip: true

    RowLayout {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      height: Theme.wbHeight
      spacing: 0

      ClockDate {}
      Connectivity {}
      DeviceStatus {}
    }
  }
}
