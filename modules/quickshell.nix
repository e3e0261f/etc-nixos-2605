{ config, pkgs, inputs, ... }:

let
  quickshell = inputs.quickshell.packages.${pkgs.system}.default;

  # ============================================================
  # 赛博极简 1px 边缘感知 HUD 主题
  # ============================================================
theme = {
    # 边缘厚度：先设为 2px 方便肉眼调试，后续可随时改回 1
    edgeThickness = 2;

    # 四边专属赛博高亮色（绝不混入背景暗色）
    topColor    = "#00f0ff"; # 上：电光青
    bottomColor = "#ff007f"; # 下：霓虹粉
    leftColor   = "#00ff88"; # 左：翡翠绿
    rightColor  = "#ffb700"; # 右：琥珀金
  };

  shellQml = ''
    import QtQuick
    import Quickshell
    import Quickshell.Hyprland

    ShellRoot {
        id: root

        // ========================================================
        // 1. 【上边 Top】：屏幕顶部横向光轨
        // ========================================================
        Variants {
            model: Quickshell.screens

            PanelWindow {
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }

                height: ${toString theme.edgeThickness}
                exclusionMode: ExclusionMode.Ignore
                aboveWindows: true
                focusable: false
                color: "transparent"

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    height: parent.height
                    // 默认占屏幕 70% 宽度
                    width: parent.width * 1.0
                    color: "${theme.topColor}"
                }
            }
        }

        // ========================================================
        // 2. 【下边 Bottom】：屏幕底部横向光轨
        // ========================================================
        Variants {
            model: Quickshell.screens

            PanelWindow {
                required property var modelData
                screen: modelData

                anchors {
                    bottom: true
                    left: true
                    right: true
                }

                height: ${toString theme.edgeThickness}
                exclusionMode: ExclusionMode.Ignore
                aboveWindows: true
                focusable: false
                color: "transparent"

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: parent.height
                    // 居中显示，占屏幕 50% 宽度
                    width: parent.width * 0.5
                    color: "${theme.bottomColor}"
                }
            }
        }

        // ========================================================
        // 3. 【左边 Left】：屏幕左侧纵向光轨
        // ========================================================
        Variants {
            model: Quickshell.screens

            PanelWindow {
                required property var modelData
                screen: modelData

                anchors {
                    left: true
                    top: true
                    bottom: true
                }

                width: ${toString theme.edgeThickness}
                exclusionMode: ExclusionMode.Ignore
                aboveWindows: true
                focusable: false
                color: "transparent"

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    // 居中纵向显示，占屏幕高度 50%
                    height: parent.height * 0.5
                    color: "${theme.leftColor}"
                }
            }
        }

        // ========================================================
        // 4. 【右边 Right】：屏幕右侧纵向光轨
        // ========================================================
        Variants {
            model: Quickshell.screens

            PanelWindow {
                required property var modelData
                screen: modelData

                anchors {
                    right: true
                    top: true
                    bottom: true
                }

                width: ${toString theme.edgeThickness}
                exclusionMode: ExclusionMode.Ignore
                aboveWindows: true
                focusable: false
                color: "transparent"

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    // 居中纵向显示，占屏幕高度 50%
                    height: parent.height * 0.5
                    color: "${theme.rightColor}"
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
