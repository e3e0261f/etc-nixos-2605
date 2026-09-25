
# /etc/nixos/modules/apps/apps-gui.nix
{ pkgs, ... }:

{

  # HYprland 
  programs.hyprland = {
    enable = true;
    # xwayland.enable = true; # 如果你需要執行舊的 X11 軟體，請開啟此項
  };
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-hyprland 
      pkgs.xdg-desktop-portal-xapp
    ];
    config = {
      common = {
        "org.freedesktop.impl.portal.FileChooser" = [ "xapp" "gtk" ];
      };
    };
    configPackages = [ pkgs.hyprland ];
    config.common.default = "*"; 
  };

  environment.systemPackages = with pkgs; [
    google-chrome
    # spotify
    discord
    keepassxc
    crow-translate
    gimagereader
    tesseract   #图片字符识别
    waypaper    #背景工具
    loupe       #图片检查器
    # spotify
    # ente-auth
    # hydrogen  #强大鼓机
    # supercollider
    # emacs-pgtk
    sl
    clash-verge-rev
  ];
}
