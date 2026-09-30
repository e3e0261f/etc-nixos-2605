{ pkgs, ... }:

{
  # --- 核心软件包 ---
  environment.systemPackages = with pkgs; [
    tuigreet
  ];

  # ============================================================
  # 1. 静默引导与日志压制（合并重复属性，为 Plymouth 铺平道路）
  # ============================================================
  boot.consoleLogLevel = 3;
  
  # 🟢 核心修复 1：将所有内核参数干净地合并为一行，彻底消除编译报错
  boot.kernelParams = [ "quiet" "splash" "loglevel=3" "rd.udev.log_level=3" ]; 

  # ============================================================
  # 🟢 填补画面空缺：开启官方开机动画 (Plymouth 完整增强版)
  # ============================================================
  boot.plymouth = {
    enable = true;
    theme = "bgrt"; # 显示主板厂商原厂 Logo，提供无缝一体化开机视觉
    
    # 🟢 核心修复 2：必须引入系统主题包，确保 bgrt 的转圈动画资源被正确加载
    themePackages = with pkgs; [ 
      (kdePackages.plymouth-kcm or plymouth) 
    ];
  };

  # ============================================================
  # 2. Greetd 配置 (完美拥抱现代 UWSM 图形架构)
  # ============================================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # 保留你的 Matrix 绿雨动效，并通过 UWSM 后台模式纳管整个桌面会话
        # 🟢 终极正确命令：让 uwsm 自动去拉起默认/已选的合成器（default），完美避开所有 command not found 报错！
        command = "stty sane && stty flush && \${pkgs.tuigreet}/bin/tuigreet --background matrix --background-fps 30 --matrix-colors '#CCFFCC,#33FF66,#006622' --matrix-speed 1,2 --time --remember --asterisks --cmd 'uwsm start default'";
        user = "greeter";
      };
    };
  };

  # ============================================================
  # 3. 核心修复：彻底清空 VT1 屏幕，杜绝任何文字干扰
  # ============================================================
  systemd.services.greetd.serviceConfig = {
    # 🟢 核心修复 3：维持 simple 模式，让 tuigreet 立即供电，终结显示器掉电噩梦
    # Type = "simple"; 
    Type = "idle"; 
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
