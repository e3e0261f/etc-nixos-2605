
{ pkgs, ... }:

{
  # --- 核心软件包 ---
  # 这里的包是给登录管理器使用的，tuigreet 必须安装在这里
  environment.systemPackages = with pkgs; [
    greetd.tuigreet
    # 如果你想尝试 wlgreet，也可以加在这里
    # greetd.wlgreet 
  ];

  # --- Greetd 配置 ---
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # tuigreet 参数说明：
        # -t: 显示时间
        # -c Hyprland: 登录后直接启动 Hyprland
        # --remember: 记住用户名
        # --asterisks: 输入密码时显示星号
        # 最标准的做法是使用 Hyprland 提供的启动入口
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --background matrix --time --remember --asterisks --cmd start-hyprland wrapper";
        # 注意这里改成了 uwsm start hyprland-session.target
        # command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd 'uwsm start hyprland-session.target'";
        user = "greeter";
      };
    };
  };

  # --- 系统底层优化 ---
  # 解决一些潜在的硬件/TTY问题
  services.getty.autologinUser = null; # 确保禁用自动登录，由 greetd 接管
}
