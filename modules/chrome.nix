# /etc/nixos/modules/chrome.nix
{ pkgs, ... }:{

programs.google-chrome = {
  enable = true;
  # 强制 Chrome 统一使用原生 Wayland 运行，并打通单实例通信的平台通道
  commandLineArgs = [
    "--ozone-platform-hint=auto"
    "--enable-features=WaylandWindowDecorations"
  ];
};


}
