{ config, pkgs, ... }:

{
  # 安装 Discord 客户端
  home.packages = [
    pkgs.discord
  ];

  # 强行声明并锁死配置文件，每次登录系统都会自动刷新
  xdg.configFile."discord/settings.json" = {
    text = builtins.toJSON {
      SKIP_HOST_UPDATE = true;
      openH264Enabled = true;
      BACKGROUND_COLOR = "#121214";
      offloadAdmControls = true;
      DESKTOP_TTI_DNSTCP_WARMUP = true;
      DESKTOP_TTI_SPLASH_USE_WEBP = true;
      DESKTOP_TTI_UPDATE_BACKOFF_MAX_MS = 20000;
      chromiumSwitches = {};
      # 窗口大小建议让它动态保存（force = false），或者像下面这样直接锁死
      IS_MINIMIZED = false;
      WINDOW_BOUNDS = {
        x = 16;
        y = 10;
        width = 1312;
        height = 726;
      };
    };
    # 确保这里是全小写的 force
    force = true; 
  };
}
