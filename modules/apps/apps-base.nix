# /etc/nixos/modules/apps/apps-gui.nix
{ pkgs, ... }:

{






  
  environment.systemPackages = with pkgs; [
    (discord.override {
      withOpenASAR = true;
    })
    helix wget curl unzip gh
    procps lvm2 p7zip unrar
    polkit_gnome networkmanagerapplet
    dust pciutils scanmem alsa-utils keyd
    usbutils esptool espflash tio opensc
    mpv
    
    # 桌面與視窗管理器核心組件
    hyprlauncher hyprshutdown wlogout
    hypridle hyprlock hyprpaper hyprpicker
    pamixer ddcutil brightnessctl libcava lm_sensors aubio
    libqalculate power-profiles-daemon
    material-symbols rubik cascadia-code
    qt6.qtbase
    qt6.qtimageformats
    qt6.qtdeclarative
    qt6.qtshadertools
    swappy bash fish zsh ninja glibc libgcc
    papirus-icon-theme
    playerctl
    wireplumber
    networkmanager
    
    # 圖形與音訊管理
    wl-clipboard grim slurp translate-shell
    kdePackages.ark kdePackages.dolphin kdePackages.kservice
    easyeffects pavucontrol qpwgraph crosspipe
    appimage-run
  ];
}
