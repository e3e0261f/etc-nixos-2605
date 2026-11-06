{ config, pkgs, inputs, ... }:

let
  quickshell = inputs.quickshell.packages.${pkgs.system}.default;

  # ============================================================
  # 赛博极简 1px 边缘感知 HUD 主题
  # ============================================================
  theme = {
    baseThickness = 1; # 1px 常态底线
    glowDepth = 4;     # 5px 高能收敛光晕

    bloom = {
      w1 = 3;   l1 = 175;  r1 = 7;   c1 = "#f43f5e";  a1 = 0.12;
      w2 = 3;   l2 = 105;   r2 = 4;   c2 = "#f59e0b";  a2 = 0.37;
      w3 = 2;   l3 = 65;   r3 = 1.5; c3 = "#ffea00";  a3 = 0.55;
      w4 = 1;   l4 = 25;   r4 = 0.5; c4 = "#ffffff";  a4 = 1.0;
    };

    cornerSize = 24;
    popupWidth = 260;
    popupHeight = 180;
    popupBg = "#cc141418";

    gemini = {
      blue   = "#38bdf8";
      indigo = "#6366f1";
      rose   = "#f43f5e";
      amber  = "#f59e0b";
    };
  };

  shellQml = ''
    import QtQuick
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Hyprland

    ShellRoot {
        id: root

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
        // 1. 【顶边 Top】：10点(左上) -> 12点(正中) -> 2点(右上) [4小时跨度]
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

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: ${toString theme.baseThickness}
                        antialiasing: false
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "${theme.gemini.blue}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.indigo}" }
                        }
                    }

                    Item {
                        // 10点, 11点, 12点(0点), 1点 在顶边运行
                        readonly property bool inTop: (clock.currentHour === 10 || clock.currentHour === 11 || clock.currentHour === 0 || clock.currentHour === 1)
                        visible: inTop
                        anchors.top: parent.top
                        height: parent.height
                        width: ${toString theme.bloom.l1}

                        // 顶边 4 个小时跨度从 0% 流畅滑行到 100%
                        x: {
                            var hIndex = 0
                            if (clock.currentHour === 10) hIndex = 0
                            else if (clock.currentHour === 11) hIndex = 1
                            else if (clock.currentHour === 0) hIndex = 2
                            else if (clock.currentHour === 1) hIndex = 3

                            var progress = (hIndex + clock.minuteProgress) / 4.0
                            return progress * (parent.width - width)
                        }

                        Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; height: ${toString theme.bloom.w1}; width: ${toString theme.bloom.l1}; radius: ${toString theme.bloom.r1}; color: "${theme.bloom.c1}"; opacity: ${toString theme.bloom.a1} }
                        Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; height: ${toString theme.bloom.w2}; width: ${toString theme.bloom.l2}; radius: ${toString theme.bloom.r2}; color: "${theme.bloom.c2}"; opacity: ${toString theme.bloom.a2} }
                        Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; height: ${toString theme.bloom.w3}; width: ${toString theme.bloom.l3}; radius: ${toString theme.bloom.r3}; color: "${theme.bloom.c3}"; opacity: ${toString theme.bloom.a3} }
                        Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; height: ${toString theme.bloom.w4}; width: ${toString theme.bloom.l4}; radius: ${toString theme.bloom.r4}; color: "${theme.bloom.c4}"; opacity: ${toString theme.bloom.a4} }
                    }
                }
            }
        }

        // ========================================================
        // 2. 【右边 Right】：2点(右上) -> 3点(正中) -> 4点(右下) [2小时跨度]
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
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: ${toString theme.baseThickness}
                        antialiasing: false
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "${theme.gemini.indigo}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.rose}" }
                        }
                    }

                    Item {
                        // 2点, 3点 在右边运行 (3点正好在正中间！)
                        readonly property bool inRight: (clock.currentHour === 2 || clock.currentHour === 3)
                        visible: inRight
                        anchors.right: parent.right
                        width: parent.width
                        height: ${toString theme.bloom.l1}

                        // 右边 2 个小时跨度从 0% 滑行到 100%
                        y: {
                            var hIndex = (clock.currentHour === 2) ? 0 : 1
                            var progress = (hIndex + clock.minuteProgress) / 2.0
                            return progress * (parent.height - height)
                        }

                        Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: ${toString theme.bloom.w1}; height: ${toString theme.bloom.l1}; radius: ${toString theme.bloom.r1}; color: "${theme.bloom.c1}"; opacity: ${toString theme.bloom.a1} }
                        Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: ${toString theme.bloom.w2}; height: ${toString theme.bloom.l2}; radius: ${toString theme.bloom.r2}; color: "${theme.bloom.c2}"; opacity: ${toString theme.bloom.a2} }
                        Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: ${toString theme.bloom.w3}; height: ${toString theme.bloom.l3}; radius: ${toString theme.bloom.r3}; color: "${theme.bloom.c3}"; opacity: ${toString theme.bloom.a3} }
                        Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: ${toString theme.bloom.w4}; height: ${toString theme.bloom.l4}; radius: ${toString theme.bloom.r4}; color: "${theme.bloom.c4}"; opacity: ${toString theme.bloom.a4} }
                    }
                }
            }
        }

        // ========================================================
        // 3. 【底边 Bottom】：4点(右下) -> 6点(正中) -> 8点(左下) [4小时跨度]
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
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: ${toString theme.baseThickness}
                        antialiasing: false
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "${theme.gemini.amber}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.rose}" }
                        }
                    }

                    Item {
                        // 4点, 5点, 6点, 7点 在底边顺时针向左滑行
                        readonly property bool inBottom: (clock.currentHour >= 4 && clock.currentHour <= 7)
                        visible: inBottom
                        anchors.bottom: parent.bottom
                        height: parent.height
                        width: ${toString theme.bloom.l1}

                        // 底边从右(4点)向左(8点)行进
                        x: {
                            var hIndex = clock.currentHour - 4
                            var progress = (hIndex + clock.minuteProgress) / 4.0
                            return (1.0 - progress) * (parent.width - width)
                        }

                        Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; height: ${toString theme.bloom.w1}; width: ${toString theme.bloom.l1}; radius: ${toString theme.bloom.r1}; color: "${theme.bloom.c1}"; opacity: ${toString theme.bloom.a1} }
                        Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; height: ${toString theme.bloom.w2}; width: ${toString theme.bloom.l2}; radius: ${toString theme.bloom.r2}; color: "${theme.bloom.c2}"; opacity: ${toString theme.bloom.a2} }
                        Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; height: ${toString theme.bloom.w3}; width: ${toString theme.bloom.l3}; radius: ${toString theme.bloom.r3}; color: "${theme.bloom.c3}"; opacity: ${toString theme.bloom.a3} }
                        Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; height: ${toString theme.bloom.w4}; width: ${toString theme.bloom.l4}; radius: ${toString theme.bloom.r4}; color: "${theme.bloom.c4}"; opacity: ${toString theme.bloom.a4} }
                    }
                }
            }
        }

        // ========================================================
        // 4. 【左边 Left】：8点(左下) -> 9点(正中) -> 10点(左上) [2小时跨度]
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
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: ${toString theme.baseThickness}
                        antialiasing: false
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "${theme.gemini.blue}" }
                            GradientStop { position: 1.0; color: "${theme.gemini.amber}" }
                        }
                    }

                    Item {
                        // 8点, 9点 在左边顺时针向上滑行 (9点正好在正中间！)
                        readonly property bool inLeft: (clock.currentHour === 8 || clock.currentHour === 9)
                        visible: inLeft
                        anchors.left: parent.left
                        width: parent.width
                        height: ${toString theme.bloom.l1}

                        // 左边从底(8点)向上(10点)行进
                        y: {
                            var hIndex = (clock.currentHour === 8) ? 0 : 1
                            var progress = (hIndex + clock.minuteProgress) / 2.0
                            return (1.0 - progress) * (parent.height - height)
                        }

                        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: ${toString theme.bloom.w1}; height: ${toString theme.bloom.l1}; radius: ${toString theme.bloom.r1}; color: "${theme.bloom.c1}"; opacity: ${toString theme.bloom.a1} }
                        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: ${toString theme.bloom.w2}; height: ${toString theme.bloom.l2}; radius: ${toString theme.bloom.r2}; color: "${theme.bloom.c2}"; opacity: ${toString theme.bloom.a2} }
                        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: ${toString theme.bloom.w3}; height: ${toString theme.bloom.l3}; radius: ${toString theme.bloom.r3}; color: "${theme.bloom.c3}"; opacity: ${toString theme.bloom.a3} }
                        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: ${toString theme.bloom.w4}; height: ${toString theme.bloom.l4}; radius: ${toString theme.bloom.r4}; color: "${theme.bloom.c4}"; opacity: ${toString theme.bloom.a4} }
                    }
                }
            }
        }

        // ========================================================
        // 4 个角落功能热区（左下角弹出时间）
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
                    onTriggered: {
                        winBL.isOpen = false
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        timerBL.stop()
                        winBL.isOpen = true
                    }
                    onExited: {
                        timerBL.restart()
                    }

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
                            Text {
                                text: clock.fullDateString
                                color: "#a1a1aa"
                                font.pixelSize: 12
                            }
                            Text {
                                text: clock.fullTimeString
                                color: "${theme.gemini.amber}"
                                font.family: "JetBrains Mono"
                                font.bold: true
                                font.pixelSize: 26
                            }
                            Text {
                                text: "• 宽屏自适应物理时钟 (顶4/右2/底4/左2)"
                                color: "#71717a"
                                font.pixelSize: 11
                            }
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
                    onTriggered: {
                        winTL.isOpen = false
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        timerTL.stop()
                        winTL.isOpen = true
                    }
                    onExited: {
                        timerTL.restart()
                    }

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
                            Text {
                                text: "⬡ 左上角功能区 (10点)"
                                color: "${theme.gemini.blue}"
                                font.bold: true
                                font.pixelSize: 13
                            }
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
                    onTriggered: {
                        winTR.isOpen = false
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        timerTR.stop()
                        winTR.isOpen = true
                    }
                    onExited: {
                        timerTR.restart()
                    }

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
                            Text {
                                text: "⬡ 右上角功能区 (2点)"
                                color: "${theme.gemini.indigo}"
                                font.bold: true
                                font.pixelSize: 13
                            }
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
                    onTriggered: {
                        winBR.isOpen = false
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        timerBR.stop()
                        winBR.isOpen = true
                    }
                    onExited: {
                        timerBR.restart()
                    }

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
                            Text {
                                text: "⬡ 右下角功能区 (4点)"
                                color: "${theme.gemini.rose}"
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
