{ config, pkgs, inputs, ... }:

let
  quickshell = inputs.quickshell.packages.${pkgs.system}.default;

  # ============================================================
  # 赛博极简 1px 边缘感知 HUD 主题
  # ============================================================
  theme = {
    baseThickness = 1;
    glowDepth = 14;
    trackOpacity = 0.18;
    alarmColor = "#38bdf8";

    ticks = {
      m1_h  = 5;   m1_w  = 1;
      m5_h  = 6;   m5_w  = 1;
      m10_h = 7;   m10_w = 1;
      m30_h = 5;   m30_w = 2;
      m60_h = 6;   m60_w = 2;

      boost_m1_h  = 7;   boost_m1_w  = 1;
      boost_m5_h  = 8;  boost_m5_w  = 1;
      boost_m10_h = 9;  boost_m10_w = 1;
      boost_m30_h = 7;  boost_m30_w = 2;
      boost_m60_h = 8;  boost_m60_w = 3;

      color         = "#94a3b8";
      hourColor     = "#ffffff";
      halfHourColor = "#fde047";
    };

    alarm = {
      defaultHour   = 7;
      defaultMinute = 30;
      hourStep      = 1;
      minuteStep    = 5;
    };

    beam = {
      baseLength  = 320;
      boostLength = 580;
      baseCurveHeight  = 6.0;
      boostCurveHeight = 11.0;
    };

    gemini = {
      vacuum = "#1e1b4b";
      cyan   = "#38bdf8";
      purple = "#c084fc";
      dark   = "#27272a";
      blue   = "#38bdf8";
      indigo = "#6366f1";
      rose   = "#f43f5e";
      amber  = "#f59e0b";
      white  = "#ffffff";
      gold   = "#fde047";
      coral  = "#fb7185";
    };

    cornerSize = 24;
    popupWidth = 280;
    popupHeight = 240;
    popupBg = "#cc141418";
  };

  shellQml = ''
    import QtQuick
    import QtQuick.Shapes
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Hyprland
    import Quickshell.Io

    ShellRoot {
        id: root

        property bool chimeEnabled: true
        property int lastChimedHour: -1

        property bool alarmEnabled: true
        property int alarmHour: ${toString theme.alarm.defaultHour}
        property int alarmMinute: ${toString theme.alarm.defaultMinute}

        property bool boostGlow: false
        property string currentWifi: "检测中..."
        property string currentIme: "EN"

        readonly property int tickM1_H: root.boostGlow ? ${toString theme.ticks.boost_m1_h} : ${toString theme.ticks.m1_h};
        readonly property int tickM1_W: root.boostGlow ? ${toString theme.ticks.boost_m1_w} : 1;
        readonly property int tickM5_H: root.boostGlow ? ${toString theme.ticks.boost_m5_h} : ${toString theme.ticks.m5_h};
        readonly property int tickM5_W: root.boostGlow ? ${toString theme.ticks.boost_m5_w} : 1;
        readonly property int tickM10_H: root.boostGlow ? ${toString theme.ticks.boost_m10_h} : ${toString theme.ticks.m10_h};
        readonly property int tickM10_W: root.boostGlow ? ${toString theme.ticks.boost_m10_w} : 1;
        readonly property int tickM30_H: root.boostGlow ? ${toString theme.ticks.boost_m30_h} : ${toString theme.ticks.m30_h};
        readonly property int tickM30_W: root.boostGlow ? ${toString theme.ticks.boost_m30_w} : 1;
        readonly property int tickM60_H: root.boostGlow ? ${toString theme.ticks.boost_m60_h} : ${toString theme.ticks.m60_h};
        readonly property int tickM60_W: root.boostGlow ? ${toString theme.ticks.boost_m60_w} : ${toString theme.ticks.m60_w};

        property real minuteBlink: 1.0
        SequentialAnimation on minuteBlink {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 0.15; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 600; easing.type: Easing.InOutSine }
        }

        property real waveHarmonic1: 0.0
        property real waveHarmonic2: 0.0
        readonly property real fluidShift: (waveHarmonic1 * 0.09) + (waveHarmonic2 * 0.05)

        SequentialAnimation on waveHarmonic1 {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 1.0; duration: 3200; easing.type: Easing.InOutSine }
            NumberAnimation { to: -1.0; duration: 3200; easing.type: Easing.InOutSine }
        }

        SequentialAnimation on waveHarmonic2 {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 1.0; duration: 1900; easing.type: Easing.InOutQuad }
            NumberAnimation { to: -1.0; duration: 1900; easing.type: Easing.InOutQuad }
        }

        property real beaconPulse: 0.8
        SequentialAnimation on beaconPulse {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 0.3; duration: 1500; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
        }

        QtObject {
            id: clock
            property int currentHour: 0
            property int currentMinute: 0
            property int currentSecond: 0
            property real minuteProgress: 0.0
            property string fullTimeString: ""
            property string fullDateString: ""

            readonly property int totalMinutes: (currentHour % 12) * 60 + currentMinute
            readonly property int prevAnchorMin: Math.floor(totalMinutes / 30) * 30
            readonly property int nextAnchorMin: (prevAnchorMin + 30) % 720
        }

        Process {
            id: soundPlayer
            function play(name) {
                command = ["canberra-gtk-play", "-i", name, "-V", "-12.0"]
                running = true
            }
        }

        Connections {
            target: Hyprland
            function onFocusedWorkspaceChanged() {
                soundPlayer.play("button-pressed")
            }
        }

        Process {
            id: wifiProcess
            command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 2>/dev/null || echo '未连接'"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var s = text.trim()
                    root.currentWifi = s.length > 0 ? s : "未连接"
                }
            }
        }

        Process {
            id: imeProcess
            command: ["sh", "-c", "fcitx5-remote -n 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var val = text.trim()
                    var isZh = (val.indexOf("pinyin") !== -1 || val.indexOf("shuangpin") !== -1)
                    root.currentIme = isZh ? "中 (拼音)" : "EN (英文)"
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                var now = new Date()
                var h = now.getHours()
                var m = now.getMinutes()
                var s = now.getSeconds()

                clock.currentHour = h % 12
                clock.currentMinute = m
                clock.currentSecond = s
                clock.minuteProgress = (m * 60 + s) / 3600.0
                clock.fullTimeString = Qt.formatDateTime(now, "hh:mm:ss")
                clock.fullDateString = Qt.formatDateTime(now, "yyyy-MM-dd dddd")

                if (root.chimeEnabled && m === 0 && s === 0 && root.lastChimedHour !== h) {
                    root.lastChimedHour = h
                    soundPlayer.play("audio-volume-change")
                }

                if (root.alarmEnabled && clock.currentHour === (root.alarmHour % 12) && m === root.alarmMinute && s === 0) {
                    soundPlayer.play("bell")
                }

                if (s % 3 === 0) {
                    wifiProcess.running = false
                    wifiProcess.running = true
                    imeProcess.running = false
                    imeProcess.running = true
                }
            }
        }

        // ========================================================
        // 1. 【顶边 Top】
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                id: topWin
                required property var modelData
                screen: modelData
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: root.boostGlow ? 20 : ${toString theme.glowDepth}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Item {
                    id: topContainer
                    anchors.fill: parent

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        antialiasing: false
                        opacity: ${toString theme.trackOpacity}
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "${theme.gemini.cyan}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.purple}" }
                        }
                    }

                    Repeater {
                        model: [clock.prevAnchorMin, clock.nextAnchorMin]
                        Rectangle {
                            readonly property int anchorM: modelData
                            readonly property bool onTop: (anchorM >= 600 || anchorM <= 120)
                            readonly property bool inCurrentHourSlot: Math.floor(anchorM / 60) === Math.floor(clock.totalMinutes / 60)
                            visible: onTop && inCurrentHourSlot

                            readonly property real normalizedM: (anchorM >= 600) ? (anchorM - 600) : (anchorM + 120)
                            x: (normalizedM / 240.0) * topContainer.width - (width / 2.0)
                            anchors.top: parent.top

                            width: (anchorM % 60 === 0) ? root.tickM60_W : root.tickM30_W
                            height: (anchorM % 60 === 0) ? root.tickM60_H : root.tickM30_H
                            color: (anchorM % 60 === 0) ? "${theme.ticks.hourColor}" : "${theme.ticks.halfHourColor}"
                            opacity: 0.85
                            antialiasing: false
                        }
                    }

                    Rectangle {
                        readonly property bool hasAlarm: root.alarmEnabled && (root.alarmHour % 12 === 10 || root.alarmHour % 12 === 11 || root.alarmHour % 12 === 0 || root.alarmHour % 12 === 1)
                        visible: hasAlarm
                        anchors.top: parent.top
                        width: 3
                        height: 3
                        radius: 1.5
                        color: "${theme.alarmColor}"
                        opacity: root.beaconPulse
                        x: {
                            var aH = root.alarmHour % 12
                            var hIdx = (aH === 10) ? 0 : ((aH === 11) ? 1 : ((aH === 0) ? 2 : 3))
                            var prog = (hIdx + (root.alarmMinute / 60.0)) / 4.0
                            return prog * topContainer.width - 1.5
                        }
                    }

                    Item {
                        id: topBeam
                        readonly property bool inTop: (clock.currentHour === 10 || clock.currentHour === 11 || clock.currentHour === 0 || clock.currentHour === 1)
                        visible: inTop
                        anchors.top: parent.top
                        height: topContainer.height
                        width: root.boostGlow ? ${toString theme.beam.boostLength} : ${toString theme.beam.baseLength}

                        x: {
                            var hIndex = (clock.currentHour === 10) ? 0 : ((clock.currentHour === 11) ? 1 : ((clock.currentHour === 0) ? 2 : 3))
                            var progress = (hIndex + clock.minuteProgress) / 4.0
                            return progress * topContainer.width - (topBeam.width / 2.0)
                        }

                        Repeater {
                            model: 37
                            Rectangle {
                                readonly property int deltaMin: index - 18
                                readonly property int targetMin: ((clock.currentMinute + deltaMin) % 60 + 60) % 60
                                readonly property real pxPerMin: topContainer.width / 240.0
                                readonly property real xOffset: (deltaMin - (clock.currentSecond / 60.0)) * pxPerMin
                                readonly property real distRatio: Math.abs(xOffset) / (topBeam.width / 2.0)
                                readonly property bool isSubMinute: (targetMin % 30 !== 0)

                                visible: isSubMinute && distRatio <= 0.78
                                opacity: (deltaMin === 0)
                                    ? root.minuteBlink
                                    : Math.max(0.0, (1.0 - distRatio * 1.1) * 0.75)

                                anchors.top: parent.top
                                x: (topBeam.width / 2.0) + xOffset - (width / 2.0)

                                width: (targetMin % 10 === 0) ? root.tickM10_W : ((targetMin % 5 === 0) ? root.tickM5_W : root.tickM1_W)
                                height: (targetMin % 10 === 0) ? root.tickM10_H :
                                        ((targetMin % 5 === 0) ? root.tickM5_H : root.tickM1_H)
                                color: "${theme.ticks.color}"
                                antialiasing: false
                            }
                        }

                        Shape {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: topBeam.width
                            height: root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight}
                            layer.enabled: true
                            layer.samples: 4
                            ShapePath {
                                strokeWidth: 0
                                fillColor: "transparent"
                                startX: 0
                                startY: 0
                                fillGradient: LinearGradient {
                                    x1: 0; y1: 0; x2: topBeam.width; y2: 0
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: Math.max(0.1, 0.35 + root.fluidShift); color: "${theme.gemini.purple}" }
                                    GradientStop { position: Math.min(0.9, 0.65 + root.fluidShift); color: "${theme.gemini.gold}" }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                                PathCubic {
                                    x: topBeam.width; y: 0
                                    control1X: topBeam.width * 0.3
                                    control1Y: root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight}
                                    control2X: topBeam.width * 0.7
                                    control2Y: root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight}
                                }
                                PathLine { x: 0; y: 0 }
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: topBeam.width * 0.85
                            height: root.boostGlow ? 2 : 1
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: Math.max(0.05, 0.20 + root.fluidShift); color: "${theme.gemini.cyan}" }
                                GradientStop { position: Math.max(0.15, 0.38 + root.fluidShift); color: "${theme.gemini.purple}" }
                                GradientStop { position: Math.min(0.85, 0.50 + root.fluidShift); color: "${theme.gemini.white}" }
                                GradientStop { position: Math.min(0.90, 0.62 + root.fluidShift); color: "${theme.gemini.gold}" }
                                GradientStop { position: Math.min(0.95, 0.80 + root.fluidShift); color: "${theme.gemini.coral}" }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        // 2. 【右边 Right】
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                id: rightWin
                required property var modelData
                screen: modelData
                anchors {
                    right: true
                    top: true
                    bottom: true
                }
                implicitWidth: root.boostGlow ? 20 : ${toString theme.glowDepth}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Item {
                    id: rightContainer
                    anchors.fill: parent

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        antialiasing: false
                        opacity: ${toString theme.trackOpacity}
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "${theme.gemini.purple}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.coral}" }
                        }
                    }

                    Repeater {
                        model: [clock.prevAnchorMin, clock.nextAnchorMin]
                        Rectangle {
                            readonly property int anchorM: modelData
                            readonly property bool onRight: (anchorM >= 120 && anchorM <= 240)
                            readonly property bool inCurrentHourSlot: Math.floor(anchorM / 60) === Math.floor(clock.totalMinutes / 60)
                            visible: onRight && inCurrentHourSlot

                            y: ((anchorM - 120) / 120.0) * rightContainer.height - (height / 2.0)
                            anchors.right: parent.right

                            height: (anchorM % 60 === 0) ? root.tickM60_W : root.tickM30_W
                            width: (anchorM % 60 === 0) ? root.tickM60_H : root.tickM30_H
                            color: (anchorM % 60 === 0) ? "${theme.ticks.hourColor}" : "${theme.ticks.halfHourColor}"
                            opacity: 0.85
                            antialiasing: false
                        }
                    }

                    Rectangle {
                        readonly property bool hasAlarm: root.alarmEnabled && (root.alarmHour % 12 === 2 || root.alarmHour % 12 === 3)
                        visible: hasAlarm
                        anchors.right: parent.right
                        width: 3
                        height: 3
                        radius: 1.5
                        color: "${theme.alarmColor}"
                        opacity: root.beaconPulse
                        y: {
                            var aH = root.alarmHour % 12
                            var hIdx = (aH === 2) ? 0 : 1
                            var prog = (hIdx + (root.alarmMinute / 60.0)) / 2.0
                            return prog * rightContainer.height - 1.5
                        }
                    }

                    Item {
                        id: rightBeam
                        readonly property bool inRight: (clock.currentHour === 2 || clock.currentHour === 3)
                        visible: inRight
                        anchors.right: parent.right
                        width: rightContainer.width
                        height: root.boostGlow ? ${toString theme.beam.boostLength} : ${toString theme.beam.baseLength}

                        y: {
                            var hIndex = (clock.currentHour === 2) ? 0 : 1
                            var progress = (hIndex + clock.minuteProgress) / 2.0
                            return progress * rightContainer.height - (rightBeam.height / 2.0)
                        }

                        Repeater {
                            model: 37
                            Rectangle {
                                readonly property int deltaMin: index - 18
                                readonly property int targetMin: ((clock.currentMinute + deltaMin) % 60 + 60) % 60
                                readonly property real pxPerMin: rightContainer.height / 120.0
                                readonly property real yOffset: (deltaMin - (clock.currentSecond / 60.0)) * pxPerMin
                                readonly property real distRatio: Math.abs(yOffset) / (rightBeam.height / 2.0)
                                readonly property bool isSubMinute: (targetMin % 30 !== 0)

                                visible: isSubMinute && distRatio <= 0.78
                                opacity: (deltaMin === 0)
                                    ? root.minuteBlink
                                    : Math.max(0.0, (1.0 - distRatio * 1.1) * 0.75)

                                anchors.right: parent.right
                                y: (rightBeam.height / 2.0) + yOffset - (height / 2.0)

                                width: (targetMin % 10 === 0) ? root.tickM10_W : ((targetMin % 5 === 0) ? root.tickM5_W : root.tickM1_W)
                                height: (targetMin % 10 === 0) ? root.tickM10_H :
                                        ((targetMin % 5 === 0) ? root.tickM5_H : root.tickM1_H)
                                color: "${theme.ticks.color}"
                                antialiasing: false
                            }
                        }

                        Shape {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight}
                            height: rightBeam.height
                            layer.enabled: true
                            layer.samples: 4
                            ShapePath {
                                strokeWidth: 0
                                fillColor: "transparent"
                                startX: rightBeam.width
                                startY: 0
                                fillGradient: LinearGradient {
                                    x1: 0; y1: 0; x2: 0; y2: rightBeam.height
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: Math.max(0.1, 0.35 + root.fluidShift); color: "${theme.gemini.purple}" }
                                    GradientStop { position: Math.min(0.9, 0.65 + root.fluidShift); color: "${theme.gemini.gold}" }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                                PathCubic {
                                    x: rightBeam.width; y: rightBeam.height
                                    control1X: rightBeam.width - (root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight})
                                    control1Y: rightBeam.height * 0.3
                                    control2X: rightBeam.width - (root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight})
                                    control2Y: rightBeam.height * 0.7
                                }
                                PathLine { x: rightBeam.width; y: 0 }
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: rightBeam.height * 0.85
                            width: root.boostGlow ? 2 : 1
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: Math.max(0.05, 0.20 + root.fluidShift); color: "${theme.gemini.cyan}" }
                                GradientStop { position: Math.max(0.15, 0.38 + root.fluidShift); color: "${theme.gemini.purple}" }
                                GradientStop { position: Math.min(0.85, 0.50 + root.fluidShift); color: "${theme.gemini.white}" }
                                GradientStop { position: Math.min(0.90, 0.62 + root.fluidShift); color: "${theme.gemini.gold}" }
                                GradientStop { position: Math.min(0.95, 0.80 + root.fluidShift); color: "${theme.gemini.coral}" }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        // 3. 【底边 Bottom】
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                id: bottomWin
                required property var modelData
                screen: modelData
                anchors {
                    bottom: true
                    left: true
                    right: true
                }
                implicitHeight: root.boostGlow ? 20 : ${toString theme.glowDepth}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Item {
                    id: bottomContainer
                    anchors.fill: parent

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        antialiasing: false
                        opacity: ${toString theme.trackOpacity}
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "${theme.gemini.gold}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.coral}" }
                        }
                    }

                    Repeater {
                        model: [clock.prevAnchorMin, clock.nextAnchorMin]
                        Rectangle {
                            readonly property int anchorM: modelData
                            readonly property bool onBottom: (anchorM >= 240 && anchorM <= 480)
                            readonly property bool inCurrentHourSlot: Math.floor(anchorM / 60) === Math.floor(clock.totalMinutes / 60)
                            visible: onBottom && inCurrentHourSlot

                            x: (1.0 - ((anchorM - 240) / 240.0)) * bottomContainer.width - (width / 2.0)
                            anchors.bottom: parent.bottom

                            width: (anchorM % 60 === 0) ? root.tickM60_W : root.tickM30_W
                            height: (anchorM % 60 === 0) ? root.tickM60_H : root.tickM30_H
                            color: (anchorM % 60 === 0) ? "${theme.ticks.hourColor}" : "${theme.ticks.halfHourColor}"
                            opacity: 0.85
                            antialiasing: false
                        }
                    }

                    Rectangle {
                        readonly property bool hasAlarm: root.alarmEnabled && (root.alarmHour >= 4 && root.alarmHour <= 7)
                        visible: hasAlarm
                        anchors.bottom: parent.bottom
                        width: 3
                        height: 3
                        radius: 1.5
                        color: "${theme.alarmColor}"
                        opacity: root.beaconPulse
                        x: {
                            var hIdx = root.alarmHour - 4
                            var prog = (hIdx + (root.alarmMinute / 60.0)) / 4.0
                            return (1.0 - prog) * bottomContainer.width - 1.5
                        }
                    }

                    Item {
                        id: bottomBeam
                        readonly property bool inBottom: (clock.currentHour >= 4 && clock.currentHour <= 7)
                        visible: inBottom
                        anchors.bottom: parent.bottom
                        height: bottomContainer.height
                        width: root.boostGlow ? ${toString theme.beam.boostLength} : ${toString theme.beam.baseLength}

                        x: {
                            var hIndex = clock.currentHour - 4
                            var progress = (hIndex + clock.minuteProgress) / 4.0
                            return (1.0 - progress) * bottomContainer.width - (bottomBeam.width / 2.0)
                        }

                        Repeater {
                            model: 37
                            Rectangle {
                                readonly property int deltaMin: index - 18
                                readonly property int targetMin: ((clock.currentMinute + deltaMin) % 60 + 60) % 60
                                readonly property real pxPerMin: bottomContainer.width / 240.0
                                readonly property real xOffset: -(deltaMin - (clock.currentSecond / 60.0)) * pxPerMin
                                readonly property real distRatio: Math.abs(xOffset) / (bottomBeam.width / 2.0)
                                readonly property bool isSubMinute: (targetMin % 30 !== 0)

                                visible: isSubMinute && distRatio <= 0.78
                                opacity: (deltaMin === 0)
                                    ? root.minuteBlink
                                    : Math.max(0.0, (1.0 - distRatio * 1.1) * 0.75)

                                anchors.bottom: parent.bottom
                                x: (bottomBeam.width / 2.0) + xOffset - (width / 2.0)

                                width: (targetMin % 10 === 0) ? root.tickM10_W : ((targetMin % 5 === 0) ? root.tickM5_W : root.tickM1_W)
                                height: (targetMin % 10 === 0) ? root.tickM10_H :
                                        ((targetMin % 5 === 0) ? root.tickM5_H : root.tickM1_H)
                                color: "${theme.ticks.color}"
                                antialiasing: false
                            }
                        }

                        Shape {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: bottomBeam.width
                            height: root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight}
                            layer.enabled: true
                            layer.samples: 4
                            ShapePath {
                                strokeWidth: 0
                                fillColor: "transparent"
                                startX: 0
                                startY: bottomBeam.height
                                fillGradient: LinearGradient {
                                    x1: bottomBeam.width; y1: 0; x2: 0; y2: 0
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: Math.max(0.1, 0.35 + root.fluidShift); color: "${theme.gemini.coral}" }
                                    GradientStop { position: Math.min(0.9, 0.65 + root.fluidShift); color: "${theme.gemini.gold}" }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                                PathCubic {
                                    x: bottomBeam.width; y: bottomBeam.height
                                    control1X: bottomBeam.width * 0.3
                                    control1Y: bottomBeam.height - (root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight})
                                    control2X: bottomBeam.width * 0.7
                                    control2Y: bottomBeam.height - (root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight})
                                }
                                PathLine { x: 0; y: bottomBeam.height }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: bottomBeam.width * 0.85
                            height: root.boostGlow ? 2 : 1
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: Math.max(0.05, 0.20 + root.fluidShift); color: "${theme.gemini.coral}" }
                                GradientStop { position: Math.max(0.15, 0.38 + root.fluidShift); color: "${theme.gemini.gold}" }
                                GradientStop { position: Math.min(0.85, 0.50 + root.fluidShift); color: "${theme.gemini.white}" }
                                GradientStop { position: Math.min(0.90, 0.62 + root.fluidShift); color: "${theme.gemini.purple}" }
                                GradientStop { position: Math.min(0.95, 0.80 + root.fluidShift); color: "${theme.gemini.cyan}" }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        // 4. 【左边 Left】
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                id: leftWin
                required property var modelData
                screen: modelData
                anchors {
                    left: true
                    top: true
                    bottom: true
                }
                implicitWidth: root.boostGlow ? 20 : ${toString theme.glowDepth}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Item {
                    id: leftContainer
                    anchors.fill: parent

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        antialiasing: false
                        opacity: ${toString theme.trackOpacity}
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "${theme.gemini.cyan}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.gold}" }
                        }
                    }

                    Repeater {
                        model: [clock.prevAnchorMin, clock.nextAnchorMin]
                        Rectangle {
                            readonly property int anchorM: modelData
                            readonly property bool onLeft: (anchorM >= 480 && anchorM <= 600)
                            readonly property bool inCurrentHourSlot: Math.floor(anchorM / 60) === Math.floor(clock.totalMinutes / 60)
                            visible: onLeft && inCurrentHourSlot

                            y: (1.0 - ((anchorM - 480) / 120.0)) * leftContainer.height - (height / 2.0)
                            anchors.left: parent.left

                            height: (anchorM % 60 === 0) ? root.tickM60_W : root.tickM30_W
                            width: (anchorM % 60 === 0) ? root.tickM60_H : root.tickM30_H
                            color: (anchorM % 60 === 0) ? "${theme.ticks.hourColor}" : "${theme.ticks.halfHourColor}"
                            opacity: 0.85
                            antialiasing: false
                        }
                    }

                    Rectangle {
                        readonly property bool hasAlarm: root.alarmEnabled && (root.alarmHour % 12 === 8 || root.alarmHour % 12 === 9)
                        visible: hasAlarm
                        anchors.left: parent.left
                        width: 3
                        height: 3
                        radius: 1.5
                        color: "${theme.alarmColor}"
                        opacity: root.beaconPulse
                        y: {
                            var aH = root.alarmHour % 12
                            var hIdx = (aH === 8) ? 0 : 1
                            var prog = (hIdx + (root.alarmMinute / 60.0)) / 2.0
                            return (1.0 - prog) * leftContainer.height - 1.5
                        }
                    }

                    Item {
                        id: leftBeam
                        readonly property bool inLeft: (clock.currentHour === 8 || clock.currentHour === 9)
                        visible: inLeft
                        anchors.left: parent.left
                        width: leftContainer.width
                        height: root.boostGlow ? ${toString theme.beam.boostLength} : ${toString theme.beam.baseLength}

                        y: {
                            var hIndex = (clock.currentHour === 8) ? 0 : 1
                            var progress = (hIndex + clock.minuteProgress) / 2.0
                            return (1.0 - progress) * leftContainer.height - (leftBeam.height / 2.0)
                        }

                        Repeater {
                            model: 37
                            Rectangle {
                                readonly property int deltaMin: index - 18
                                readonly property int targetMin: ((clock.currentMinute + deltaMin) % 60 + 60) % 60
                                readonly property real pxPerMin: leftContainer.height / 120.0
                                readonly property real yOffset: -(deltaMin - (clock.currentSecond / 60.0)) * pxPerMin
                                readonly property real distRatio: Math.abs(yOffset) / (leftBeam.height / 2.0)
                                readonly property bool isSubMinute: (targetMin % 30 !== 0)

                                visible: isSubMinute && distRatio <= 0.78
                                opacity: (deltaMin === 0)
                                    ? root.minuteBlink
                                    : Math.max(0.0, (1.0 - distRatio * 1.1) * 0.75)

                                anchors.left: parent.left
                                y: (leftBeam.height / 2.0) + yOffset - (height / 2.0)

                                width: (targetMin % 10 === 0) ? root.tickM10_W : ((targetMin % 5 === 0) ? root.tickM5_W : root.tickM1_W)
                                height: (targetMin % 10 === 0) ? root.tickM10_H :
                                        ((targetMin % 5 === 0) ? root.tickM5_H : root.tickM1_H)
                                color: "${theme.ticks.color}"
                                antialiasing: false
                            }
                        }

                        Shape {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight}
                            height: leftBeam.height
                            layer.enabled: true
                            layer.samples: 4
                            ShapePath {
                                strokeWidth: 0
                                fillColor: "transparent"
                                startX: 0
                                startY: leftBeam.height
                                fillGradient: LinearGradient {
                                    x1: 0; y1: leftBeam.height; x2: 0; y2: 0
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: Math.max(0.1, 0.35 + root.fluidShift); color: "${theme.gemini.purple}" }
                                    GradientStop { position: Math.min(0.9, 0.65 + root.fluidShift); color: "${theme.gemini.gold}" }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                                PathCubic {
                                    x: 0; y: 0
                                    control1X: root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight}
                                    control1Y: leftBeam.height * 0.7
                                    control2X: root.boostGlow ? ${toString theme.beam.boostCurveHeight} : ${toString theme.beam.baseCurveHeight}
                                    control2Y: leftBeam.height * 0.3
                                }
                                PathLine { x: 0; y: leftBeam.height }
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: leftBeam.height * 0.85
                            width: root.boostGlow ? 2 : 1
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: Math.max(0.05, 0.20 + root.fluidShift); color: "${theme.gemini.cyan}" }
                                GradientStop { position: Math.max(0.15, 0.38 + root.fluidShift); color: "${theme.gemini.purple}" }
                                GradientStop { position: Math.min(0.85, 0.50 + root.fluidShift); color: "${theme.gemini.white}" }
                                GradientStop { position: Math.min(0.90, 0.62 + root.fluidShift); color: "${theme.gemini.gold}" }
                                GradientStop { position: Math.min(0.95, 0.80 + root.fluidShift); color: "${theme.gemini.coral}" }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        // ①【左下角】：生产力中心
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                id: winBL
                required property var modelData
                screen: modelData
                anchors {
                    bottom: true
                    left: true
                }
                property bool isOpen: false
                property bool isLocked: false

                implicitWidth: isOpen ? 320 : ${toString theme.cornerSize}
                implicitHeight: isOpen ? 280 : ${toString theme.cornerSize}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Timer {
                    id: lockTimerBL
                    interval: 450
                    onTriggered: {
                        winBL.isLocked = false
                        if (!areaBL.containsMouse) {
                            timerBL.restart()
                        }
                    }
                }

                Timer {
                    id: timerBL
                    interval: 250
                    onTriggered: {
                        if (!winBL.isLocked) {
                            winBL.isOpen = false
                        }
                    }
                }

                MouseArea {
                    id: areaBL
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        timerBL.stop()
                        if (!winBL.isOpen) {
                            winBL.isOpen = true
                            winBL.isLocked = true
                            lockTimerBL.restart()
                        }
                    }
                    onExited: {
                        if (!winBL.isLocked) {
                            timerBL.restart()
                        }
                    }

                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y > 0) {
                            Hyprland.dispatch("workspace e+1")
                        } else {
                            Hyprland.dispatch("workspace e-1")
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "${theme.popupBg}"
                        radius: 14
                        border.width: 1
                        border.color: "${theme.gemini.gold}"
                        opacity: winBL.isOpen ? 1.0 : 0.0
                        scale: winBL.isOpen ? 1.0 : 0.96
                        visible: opacity > 0.0
                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Row {
                                spacing: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                                Text {
                                    text: clock.fullTimeString
                                    color: "${theme.gemini.gold}"
                                    font.family: "JetBrains Mono"
                                    font.bold: true
                                    font.pixelSize: 22
                                }
                                Text {
                                    text: clock.fullDateString
                                    color: "#a1a1aa"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                spacing: 10
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    width: 135
                                    height: 34
                                    radius: 8
                                    color: "#27272a"
                                    border.width: 1
                                    border.color: "#3f3f46"
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { text: "📶"; font.pixelSize: 11 }
                                        Text {
                                            text: root.currentWifi
                                            color: "#e4e4e7"
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: 90
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 135
                                    height: 34
                                    radius: 8
                                    color: "${theme.gemini.cyan}"
                                    border.width: 1
                                    border.color: "${theme.gemini.cyan}"
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { text: "⌨"; font.pixelSize: 12; color: "${theme.gemini.cyan}" }
                                        Text {
                                            text: root.currentIme
                                            color: "#e4e4e7"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 68
                                radius: 10
                                color: "#18181b"
                                border.width: 1
                                border.color: "${theme.gemini.purple}"
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Row {
                                        spacing: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Text {
                                            text: "WORKSPACES"
                                            color: "#71717a"
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Rectangle {
                                            width: 72
                                            height: 18
                                            radius: 9
                                            color: "#2e1065"
                                            border.width: 1
                                            border.color: "${theme.gemini.purple}"
                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { text: "✦"; color: "${theme.gemini.purple}"; font.pixelSize: 9 }
                                                Text { text: "魔术区"; color: "#f3e8ff"; font.pixelSize: 9; font.bold: true }
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Hyprland.dispatch("togglespecialworkspace magic")
                                                }
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 8
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Repeater {
                                            model: Hyprland.workspaces
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: modelData.focused ? 28 : 20
                                                height: 20
                                                radius: 10
                                                color: modelData.focused ? "${theme.gemini.gold}" : "#3f3f46"

                                                Behavior on width { NumberAnimation { duration: 150 } }
                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.id
                                                    color: modelData.focused ? "#18181b" : "#d4d4d8"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        modelData.activate()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: Hyprland.activeToplevel ? ("● " + Hyprland.activeToplevel.title) : "● 桌面就绪 (Desktop Idle)"
                                color: "#a1a1aa"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: parent.width
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        // ②【右下角】：控制中心
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                id: winBR
                required property var modelData
                screen: modelData
                anchors {
                    bottom: true
                    right: true
                }
                property bool isOpen: false
                property bool isLocked: false

                implicitWidth: isOpen ? 285 : ${toString theme.cornerSize}
                implicitHeight: isOpen ? 245 : ${toString theme.cornerSize}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Timer {
                    id: lockTimerBR
                    interval: 450
                    onTriggered: {
                        winBR.isLocked = false
                        if (!areaBR.containsMouse) {
                            timerBR.restart()
                        }
                    }
                }

                Timer {
                    id: timerBR
                    interval: 250
                    onTriggered: {
                        if (!winBR.isLocked) {
                            winBR.isOpen = false
                        }
                    }
                }

                MouseArea {
                    id: areaBR
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        timerBR.stop()
                        if (!winBR.isOpen) {
                            winBR.isOpen = true
                            winBR.isLocked = true
                            lockTimerBR.restart()
                        }
                    }
                    onExited: {
                        if (!winBR.isLocked) {
                            timerBR.restart()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "${theme.popupBg}"
                        radius: 14
                        border.width: 1
                        border.color: "${theme.gemini.coral}"
                        opacity: winBR.isOpen ? 1.0 : 0.0
                        scale: winBR.isOpen ? 1.0 : 0.96
                        visible: opacity > 0.0
                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 12

                            Text {
                                text: "⬡ 边缘光学与感官控制"
                                color: "${theme.gemini.coral}"
                                font.bold: true
                                font.pixelSize: 13
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Row {
                                width: parent.width
                                Text {
                                    text: "⚡ 极光爆发翻倍"
                                    color: root.boostGlow ? "${theme.gemini.gold}" : "#d4d4d8"
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Item { width: parent.width - 140 - 44; height: 1 }
                                Rectangle {
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.boostGlow ? "${theme.gemini.gold}" : "#3f3f46"
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.boostGlow ? (parent.width - width - 2) : 2
                                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.boostGlow = !root.boostGlow
                                            soundPlayer.play("button-pressed")
                                        }
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                Text {
                                    text: "🔔 整点轻声微音"
                                    color: "#d4d4d8"
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Item { width: parent.width - 120 - 44; height: 1 }
                                Rectangle {
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.chimeEnabled ? "#34c759" : "#3f3f46"
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.chimeEnabled ? (parent.width - width - 2) : 2
                                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.chimeEnabled = !root.chimeEnabled
                                            soundPlayer.play("button-pressed")
                                        }
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                Text {
                                    text: "📍 航标闹钟开关"
                                    color: "${theme.alarmColor}"
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Item { width: parent.width - 125 - 44; height: 1 }
                                Rectangle {
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.alarmEnabled ? "${theme.alarmColor}" : "#3f3f46"
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.alarmEnabled ? (parent.width - width - 2) : 2
                                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.alarmEnabled = !root.alarmEnabled
                                            soundPlayer.play("button-pressed")
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: 8
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: "目标时间:"
                                    color: "#94a3b8"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: "#27272a"
                                    Text { anchors.centerIn: parent; text: "-"; color: "#ffffff"; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.alarmHour = (root.alarmHour + 11) % 12
                                            soundPlayer.play("button-pressed")
                                        }
                                    }
                                }
                                Text {
                                    text: (root.alarmHour < 10 ? "0" : "") + root.alarmHour + "点"
                                    color: "${theme.alarmColor}"
                                    font.family: "JetBrains Mono"
                                    font.bold: true
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: "#27272a"
                                    Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.alarmHour = (root.alarmHour + 1) % 12
                                            soundPlayer.play("button-pressed")
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: "#27272a"
                                    Text { anchors.centerIn: parent; text: "-"; color: "#ffffff"; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.alarmMinute = (root.alarmMinute + 50) % 60
                                            soundPlayer.play("button-pressed")
                                        }
                                    }
                                }
                                Text {
                                    text: (root.alarmMinute < 10 ? "0" : "") + root.alarmMinute + "分"
                                    color: "${theme.alarmColor}"
                                    font.family: "JetBrains Mono"
                                    font.bold: true
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: "#27272a"
                                    Text { anchors.centerIn: parent; text: "+"; color: "${theme.gemini.gold}"; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.alarmMinute = (root.alarmMinute + 10) % 60
                                            soundPlayer.play("button-pressed")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        // ③【左上角】：快捷启动
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                id: winTL
                required property var modelData
                screen: modelData
                anchors {
                    top: true
                    left: true
                }
                property bool isOpen: false
                property bool isLocked: false

                implicitWidth: isOpen ? 260 : ${toString theme.cornerSize}
                implicitHeight: isOpen ? 180 : ${toString theme.cornerSize}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Timer {
                    id: lockTimerTL
                    interval: 450
                    onTriggered: {
                        winTL.isLocked = false
                        if (!areaTL.containsMouse) {
                            timerTL.restart()
                        }
                    }
                }

                Timer {
                    id: timerTL
                    interval: 280
                    onTriggered: {
                        if (!winTL.isLocked) {
                            winTL.isOpen = false
                        }
                    }
                }

                MouseArea {
                    id: areaTL
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        timerTL.stop()
                        if (!winTL.isOpen) {
                            winTL.isOpen = true
                            winTL.isLocked = true
                            lockTimerTL.restart()
                        }
                    }
                    onExited: {
                        if (!winTL.isLocked) {
                            timerTL.restart()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "${theme.popupBg}"
                        radius: 10
                        border.width: 1
                        border.color: "${theme.gemini.cyan}"
                        opacity: winTL.isOpen ? 1.0 : 0.0
                        scale: winTL.isOpen ? 1.0 : 0.96
                        visible: opacity > 0.0
                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "⬡ 快捷应用启动 (10点)"
                                color: "${theme.gemini.cyan}"
                                font.bold: true
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }
        }
    }
  '';

in
{
  home.packages = with pkgs; [
    libcanberra-gtk3
    sound-theme-freedesktop
  ];

  home.file.".config/quickshell/shell.qml".text = shellQml;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell 1px Ambient HUD";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
