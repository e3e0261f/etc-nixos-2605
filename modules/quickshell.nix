{ config, pkgs, inputs, ... }:

let
  quickshell = inputs.quickshell.packages.${pkgs.system}.default;

  # ============================================================
  # 赛博极简 1px 边缘感知 HUD 主题
  # ============================================================
theme = {
    # 调试期粗细（设为 2 或 4 方便观察，满意后调回 1）
    baseThickness = 2;

    # 【时间的特殊待遇】：时针向屏幕内溢出 10px 漫反射光晕
    glowDepth = 10;
    beamLength = 120; # 120px 流束长度

    cornerSize = 24;
    popupWidth = 260;
    popupHeight = 180;
    popupBg = "#cc141418";

    # Google Gemini 标志性四角色谱
    gemini = {
      blue   = "#38bdf8"; # 科技青蓝
      indigo = "#6366f1"; # 深度靛紫
      rose   = "#f43f5e"; # 极光玫瑰红
      amber  = "#f59e0b"; # 暖阳琥珀金
    };
  };

  shellQml = ''
    import QtQuick
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Hyprland

    ShellRoot {
        id: root

        // ========================================================
        // 12 功能通道状态数据中心 (完整保留)
        // ========================================================
        QtObject {
            id: channels
            property real topLeft: 0.0;    property real topCenter: 0.0;    property real topRight: 0.0
            property real rightTop: 0.0;   property real rightCenter: 0.0; property real rightBottom: 0.0
            property real bottomLeft: 0.0; property real bottomCenter: 0.0; property real bottomRight: 0.0
            property real leftTop: 0.0;    property real leftCenter: 0.0;   property real leftBottom: 0.0
        }

        // ========================================================
        // 核心时钟与高能流光引擎
        // ========================================================
        QtObject {
            id: clock
            property int currentHour: 0
            property real minuteProgress: 0.0
            property string fullTimeString: ""
            property string fullDateString: ""
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                var now = new Date()
                clock.currentHour = now.getHours() % 12
                clock.minuteProgress = (now.getMinutes() * 60 + now.getSeconds()) / 3600.0
                clock.fullTimeString = Qt.formatDateTime(now, "hh:mm:ss")
                clock.fullDateString = Qt.formatDateTime(now, "yyyy-MM-dd dddd")
            }
        }

        // ========================================================
        // 1. 【顶边 Top】：青蓝 -> 靛紫 (容纳 10px 向内溢出光晕)
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                required property var modelData; screen: modelData
                anchors { top: true; left: true; right: true }
                implicitHeight: ${toString theme.glowDepth}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Item {
                    anchors.fill: parent

                    // 基础 Gemini 渐变底轨
                    Rectangle {
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                        height: ${toString theme.baseThickness}
                        antialiasing: false
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "${theme.gemini.blue}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.indigo}" }
                        }
                    }

                    // 时针漫射流光 (向屏幕内溢出 10px)
                    Rectangle {
                        readonly property bool inTop: (clock.currentHour === 11 || clock.currentHour === 0 || clock.currentHour === 1)
                        visible: inTop
                        anchors.top: parent.top
                        height: ${toString theme.glowDepth}
                        width: ${toString theme.beamLength}

                        x: {
                            var baseSlot = (clock.currentHour === 11) ? 0 : ((clock.currentHour === 0) ? 1 : 2)
                            var slotW = parent.width / 3.0
                            return (baseSlot * slotW) + (slotW - width) * clock.minuteProgress
                        }

                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "#ffffffff" }
                            GradientStop { position: 0.25; color: "#e6ffea00" }
                            GradientStop { position: 0.6; color: "#6638bdf8" }
                            GradientStop { position: 1.0; color: "#00000000" }
                        }
                    }
                }
            }
        }

        // ========================================================
        // 2. 【右边 Right】：靛紫 -> 极光红 (2点, 3点, 4点)
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                required property var modelData; screen: modelData
                anchors { right: true; top: true; bottom: true }
                implicitWidth: ${toString theme.glowDepth}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Item {
                    anchors.fill: parent

                    Rectangle {
                        anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                        width: ${toString theme.baseThickness}
                        antialiasing: false
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "${theme.gemini.indigo}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.rose}" }
                        }
                    }

                    Rectangle {
                        readonly property bool inRight: (clock.currentHour >= 2 && clock.currentHour <= 4)
                        visible: inRight
                        anchors.right: parent.right
                        width: ${toString theme.glowDepth}
                        height: ${toString theme.beamLength}

                        y: {
                            var baseSlot = clock.currentHour - 2
                            var slotH = parent.height / 3.0
                            return (baseSlot * slotH) + (slotH - height) * clock.minuteProgress
                        }

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#00000000" }
                            GradientStop { position: 0.4; color: "#66f43f5e" }
                            GradientStop { position: 0.75; color: "#e6ffea00" }
                            GradientStop { position: 1.0; color: "#ffffffff" }
                        }
                    }
                }
            }
        }

        // ========================================================
        // 3. 【底边 Bottom】：琥珀金 -> 极光红 (7点, 6点, 5点)
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                required property var modelData; screen: modelData
                anchors { bottom: true; left: true; right: true }
                implicitHeight: ${toString theme.glowDepth}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Item {
                    anchors.fill: parent

                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                        height: ${toString theme.baseThickness}
                        antialiasing: false
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "${theme.gemini.amber}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.rose}" }
                        }
                    }

                    Rectangle {
                        readonly property bool inBottom: (clock.currentHour >= 5 && clock.currentHour <= 7)
                        visible: inBottom
                        anchors.bottom: parent.bottom
                        height: ${toString theme.glowDepth}
                        width: ${toString theme.beamLength}

                        x: {
                            var baseSlot = (clock.currentHour === 7) ? 0 : ((clock.currentHour === 6) ? 1 : 2)
                            var slotW = parent.width / 3.0
                            return (baseSlot * slotW) + (slotW - width) * (1.0 - clock.minuteProgress)
                        }

                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "#00000000" }
                            GradientStop { position: 0.4; color: "#66f59e0b" }
                            GradientStop { position: 0.75; color: "#e6ffea00" }
                            GradientStop { position: 1.0; color: "#ffffffff" }
                        }
                    }
                }
            }
        }

        // ========================================================
        // 4. 【左边 Left】：青蓝 -> 琥珀金 (10点, 9点, 8点)
        // ========================================================
        Variants {
            model: Quickshell.screens
            PanelWindow {
                required property var modelData; screen: modelData
                anchors { left: true; top: true; bottom: true }
                implicitWidth: ${toString theme.glowDepth}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Item {
                    anchors.fill: parent

                    Rectangle {
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        width: ${toString theme.baseThickness}
                        antialiasing: false
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "${theme.gemini.blue}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.amber}" }
                        }
                    }

                    Rectangle {
                        readonly property bool inLeft: (clock.currentHour >= 8 && clock.currentHour <= 10)
                        visible: inLeft
                        anchors.left: parent.left
                        width: ${toString theme.glowDepth}
                        height: ${toString theme.beamLength}

                        y: {
                            var baseSlot = 10 - clock.currentHour
                            var slotH = parent.height / 3.0
                            return (baseSlot * slotH) + (slotH - height) * (1.0 - clock.minuteProgress)
                        }

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#ffffffff" }
                            GradientStop { position: 0.25; color: "#e6ffea00" }
                            GradientStop { position: 0.6; color: "#6638bdf8" }
                            GradientStop { position: 1.0; color: "#00000000" }
                        }
                    }
                }
            }
        }

        // ========================================================
        // 4 个角落功能热区（语法规范化修复）
        // ========================================================

        // ①【左下角】
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
                implicitWidth: isOpen ? ${toString theme.popupWidth} : ${toString theme.cornerSize}
                implicitHeight: isOpen ? ${toString theme.popupHeight} : ${toString theme.cornerSize}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Timer {
                    id: timerBL
                    interval: 280
                    onTriggered: winBL.isOpen = false
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: { timerBL.stop(); winBL.isOpen = true }
                    onExited: { timerBL.restart() }

                    Rectangle {
                        anchors.fill: parent
                        visible: winBL.isOpen
                        color: "${theme.popupBg}"
                        radius: 10
                        border.width: 1
                        border.color: "${theme.gemini.amber}"

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: clock.fullDateString; color: "#a1a1aa"; font.pixelSize: 12 }
                            Text { text: clock.fullTimeString; color: "${theme.gemini.amber}"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 26 }
                            Text { text: "• Gemini 风格高能流光时针巡航中"; color: "#71717a"; font.pixelSize: 11 }
                        }
                    }
                }
            }
        }

        // ②【左上角】
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
                implicitWidth: isOpen ? ${toString theme.popupWidth} : ${toString theme.cornerSize}
                implicitHeight: isOpen ? ${toString theme.popupHeight} : ${toString theme.cornerSize}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Timer {
                    id: timerTL
                    interval: 280
                    onTriggered: winTL.isOpen = false
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: { timerTL.stop(); winTL.isOpen = true }
                    onExited: { timerTL.restart() }

                    Rectangle {
                        anchors.fill: parent
                        visible: winTL.isOpen
                        color: "${theme.popupBg}"
                        radius: 10
                        border.width: 1
                        border.color: "${theme.gemini.blue}"

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "⬡ 左上角功能区"; color: "${theme.gemini.blue}"; font.bold: true; font.pixelSize: 13 }
                        }
                    }
                }
            }
        }

        // ③【右上角】
        Variants {
            model: Quickshell.screens
            PanelWindow {
                id: winTR
                required property var modelData
                screen: modelData
                anchors {
                    top: true
                    right: true
                }
                property bool isOpen: false
                implicitWidth: isOpen ? ${toString theme.popupWidth} : ${toString theme.cornerSize}
                implicitHeight: isOpen ? ${toString theme.popupHeight} : ${toString theme.cornerSize}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Timer {
                    id: timerTR
                    interval: 280
                    onTriggered: winTR.isOpen = false
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: { timerTR.stop(); winTR.isOpen = true }
                    onExited: { timerTR.restart() }

                    Rectangle {
                        anchors.fill: parent
                        visible: winTR.isOpen
                        color: "${theme.popupBg}"
                        radius: 10
                        border.width: 1
                        border.color: "${theme.gemini.indigo}"

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "⬡ 右上角功能区"; color: "${theme.gemini.indigo}"; font.bold: true; font.pixelSize: 13 }
                        }
                    }
                }
            }
        }

        // ④【右下角】
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
                implicitWidth: isOpen ? ${toString theme.popupWidth} : ${toString theme.cornerSize}
                implicitHeight: isOpen ? ${toString theme.popupHeight} : ${toString theme.cornerSize}
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                Timer {
                    id: timerBR
                    interval: 280
                    onTriggered: winBR.isOpen = false
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: { timerBR.stop(); winBR.isOpen = true }
                    onExited: { timerBR.restart() }

                    Rectangle {
                        anchors.fill: parent
                        visible: winBR.isOpen
                        color: "${theme.popupBg}"
                        radius: 10
                        border.width: 1
                        border.color: "${theme.gemini.rose}"

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "⬡ 右下角功能区"; color: "${theme.gemini.rose}"; font.bold: true; font.pixelSize: 13 }
                        }
                    }
                }
            }
        }
    }
  '';
in
{
  # 依赖：用于播放超低延迟通知声音的 canberra 工具
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
      ExecStart =
        "${quickshell}/bin/quickshell "
        + "-c ${config.home.homeDirectory}/.config/quickshell/shell.qml";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
