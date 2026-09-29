{ pkgs, ... }:

{
  # --- 核心软件包 ---
  environment.systemPackages = with pkgs; [
    tuigreet
  ];

  # ============================================================
  # 1. 静默引导与日志压制（彻底禁止 dae 等服务文字打乱屏幕）
  # ============================================================
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"  # ⭐️ 核心：禁止 systemd 在控制台输出 [ OK ] Started dae.service
    "rd.udev.log_level=3"
  ];

  # ============================================================
  # 2. Greetd 配置（隔离到独立 TTY2）
  # ============================================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # 保留你原本配置的 Matrix 炫酷黑客帝国背景动效与参数
        command = "${pkgs.tuigreet}/bin/tuigreet --background matrix --background-fps 30 --matrix-colors '#CCFFCC,#33FF66,#006622' --matrix-speed 1,2 --time --remember --asterisks --cmd 'start-hyprland wrapper'";
        user = "greeter";
      };
    };
  };

  # ============================================================
  # 3. Greetd 服务时序与输出保护
  # ============================================================
  systemd.services.greetd.serviceConfig = {
    Type = "idle"; # ⭐️ 等后台服务（如 dae）基本加载完毕后再优雅绘制界面，杜绝并发插播
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # 错误日志进系统后台，绝不直接喷到 TTY 屏幕上
  };

  # --- 系统底层优化 ---
  services.getty.autologinUser = null; # 确保禁用自动登录，由 greetd 接管
}
