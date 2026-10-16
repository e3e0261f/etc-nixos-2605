{ config, pkgs, inputs, ... }:

let
  # ============================================================
  # Quickshell
  # ============================================================

  quickshell =
    inputs.quickshell.packages.${pkgs.system}.default;

  # ============================================================
  # Cyber / Apple 风格主题
  #
  # 这里是以后主要修改的地方。
  # 不要到 QML 里面到处找颜色和尺寸。
  # ============================================================

  theme = {
    # 主体
    background = "#151515";
    foreground = "#f5f5f5";
    muted = "#8b8b8b";
    border = "#2d2d2d";

    # 当前状态
    active = "#ffffff";
    activeText = "#111111";

    # 工作区
    workspace = "#292929";
    workspaceText = "#aaaaaa";

    # 尺寸
    height = 40;
    radius = 20;

    # 与屏幕边缘的距离
    marginTop = 12;

    # 内部间距
    horizontalPadding = 16;
    spacing = 12;

    # 当前窗口最大显示宽度
    windowTitleWidth = 240;
  };

  # ============================================================
  # 功能开关
  #
  # 后续增加功能时优先在这里控制。
  # ============================================================

  features = {
    workspaces = true;
    activeWindow = true;
    inputMethod = true;

    # 后续实现
    windowList = true;
    audio = false;
    network = false;
    battery = false;
    notifications = false;
    tray = false;
  };

  # ============================================================
  # QML
  #
  # 这是 Nix 生成的运行时文件。
  # 主题参数全部由上面的 Nix 注入。
  # ============================================================

  shellQml = ''
    import QtQuick
    import Quickshell
    import Quickshell.Hyprland
    import Quickshell.Io

    ShellRoot {
        id: root

        // --------------------------------------------------------
        // 状态
        // --------------------------------------------------------

        property string inputMethod: "—"

        // --------------------------------------------------------
        // 输入法
        //
        // 当前默认按照 Fcitx5 处理。
        // --------------------------------------------------------

        Process {
            id: inputMethodProcess

            command: [
                "sh",
                "-c",
                "fcitx5-remote -n 2>/dev/null"
            ]

            stdout: StdioCollector {
                onStreamFinished: {
                    var value = text.trim()

                    if (value.length > 0)
                        root.inputMethod = value
                    else
                        root.inputMethod = "—"
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true

            onTriggered: {
                inputMethodProcess.running = false
                inputMethodProcess.running = true
            }
        }

        // --------------------------------------------------------
        // 每个显示器一个浮动状态胶囊
        // --------------------------------------------------------

        Variants {
            model: Quickshell.screens

            PanelWindow {
                required property var modelData

                screen: modelData

                anchors {
                    top: true
                }

                margins.top: ${toString theme.marginTop}

                implicitWidth: 760
                implicitHeight: ${toString theme.height}

                // 不占用桌面布局空间
                exclusionMode: ExclusionMode.Ignore

                // 永远浮在窗口上方
                aboveWindows: true

                // 状态栏本身不抢焦点
                focusable: false

                color: "transparent"

                Rectangle {
                    id: capsule

                    anchors.centerIn: parent

                    width: contentRow.implicitWidth
                        + ${toString (theme.horizontalPadding * 2)}
                    height: ${toString theme.height}

                    radius: ${toString theme.radius}

                    color: "${theme.background}"

                    border.width: 1
                    border.color: "${theme.border}"

                    // ------------------------------------------------
                    // 内容
                    // ------------------------------------------------

                    Row {
                        id: contentRow

                        anchors.centerIn: parent

                        spacing: ${toString theme.spacing}

                        // =================================================
                        // 工作区
                        // =================================================

                        Row {
                            visible: ${if features.workspaces then "true" else "false"}

                            spacing: 5

                            Repeater {
                                model: Hyprland.workspaces

                                delegate: Rectangle {
                                    required property var modelData

                                    width: modelData.focused ? 24 : 18
                                    height: 24

                                    radius: 12

                                    color: modelData.focused
                                        ? "${theme.active}"
                                        : "${theme.workspace}"

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent

                                        text: modelData.id

                                        color: modelData.focused
                                            ? "${theme.activeText}"
                                            : "${theme.workspaceText}"

                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 11
                                        font.bold: modelData.focused
                                    }

                                    MouseArea {
                                        anchors.fill: parent

                                        onClicked: {
                                            modelData.activate()
                                        }

                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }

                        // =================================================
                        // 分隔线
                        // =================================================

                        Rectangle {
                            visible:
                                ${if features.workspaces && features.activeWindow
                                  then "true"
                                  else "false"}

                            width: 1
                            height: 20

                            color: "${theme.border}"
                        }

                        // =================================================
                        // 当前活动窗口
                        // =================================================

                        Row {
                            visible: ${if features.activeWindow then "true" else "false"}

                            spacing: 7

                            Text {
                                text: "●"

                                color: "${theme.foreground}"

                                font.pixelSize: 9
                            }

                            Text {
                                width: ${toString theme.windowTitleWidth}

                                text:
                                    Hyprland.activeToplevel
                                        ? Hyprland.activeToplevel.title
                                        : "Desktop"

                                color: "${theme.foreground}"

                                font.family: "JetBrains Mono"
                                font.pixelSize: 12

                                elide: Text.ElideRight
                            }
                        }

                        // =================================================
                        // 分隔线
                        // =================================================

                        Rectangle {
                            visible:
                                ${if features.activeWindow && features.inputMethod
                                  then "true"
                                  else "false"}

                            width: 1
                            height: 20

                            color: "${theme.border}"
                        }

                        // =================================================
                        // 输入法
                        // =================================================

                        Row {
                            visible: ${if features.inputMethod then "true" else "false"}

                            spacing: 6

                            Text {
                                text: "⌨"

                                color: "${theme.muted}"

                                font.pixelSize: 13
                            }

                            Text {
                                text: root.inputMethod

                                color: "${theme.foreground}"

                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
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
  # ============================================================
  # 字体
  # ============================================================

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # ============================================================
  # Quickshell 配置
  # ============================================================

  home.file.".config/quickshell/shell.qml".text = shellQml;

  # ============================================================
  # Quickshell 用户服务
  # ============================================================

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart =
        "${quickshell}/bin/quickshell "
        + "-c ${config.home.homeDirectory}/.config/quickshell/shell.qml";

      Restart = "on-failure";
      RestartSec = 3;

      # 不让 systemd 把 shell 的标准输出吞掉
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
