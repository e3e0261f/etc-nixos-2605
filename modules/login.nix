{ pkgs, ... }:

{
  # --- 核心软件包 ---
  environment.systemPackages = with pkgs; [
    tuigreet
  ];

  # ============================================================
  # 1. 静默引导与日志压制（禁止开机服务向屏幕乱打状态）
  # ============================================================
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    # "systemd.show_status=auto" # ⭐️ 禁止 systemd 输出 [ OK ] Started dae.service
    "rd.udev.log_level=3"
  ];

  # ============================================================
  # 2. Greetd 配置
  # ============================================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # 保留你的 Matrix 绿雨动效与启动命令
        command = "${pkgs.tuigreet}/bin/tuigreet --background matrix --background-fps 30 --matrix-colors '#CCFFCC,#33FF66,#006622' --matrix-speed 1,2 --time --remember --asterisks --cmd 'start-hyprland wrapper'";
        user = "greeter";
      };
    };
  };

  # ============================================================
  # 3. 核心修复：彻底清空 VT1 屏幕，杜绝任何文字干扰
  # ============================================================
  systemd.services.greetd.serviceConfig = {
    Type = "idle"; # ⭐️ 等后台服务（如 dae）就绪后再绘制界面
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # 错误信息进 journal 日志，绝不喷到屏幕

    # ⭐️ 核心三件套：启动 tuigreet 前瞬间清空 VT1 屏幕上的所有残留文字
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # --- 系统底层优化 ---
  services.getty.autologinUser = null; # 确保禁用自动登录，由 greetd 接管
}
