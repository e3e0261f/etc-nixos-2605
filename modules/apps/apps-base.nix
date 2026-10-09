# /etc/nixos/modules/apps/apps-gui.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (discord.override {
      withOpenASAR = true;
    })
    helix gnupg wget curl unzip gh pstree
    procps lvm2 p7zip unrar parted gptfdisk
    dust pciutils scanmem alsa-utils keyd
    usbutils esptool espflash tio opensc
    mpv cloudflared killall
              # Rust 开发工具链
          rustc
          cargo
          clippy
          rustfmt
          
          # 网页编译目标 (WebAssembly)
          wasm-bindgen-cli
          
          # 项目构建工具
          trunk
          
          # 系统依赖
          pkg-config
          libxkbcommon
          libGL
          wayland
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr

    
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
    networkmanager
    
    # 圖形與音訊管理
    wl-clipboard grim slurp translate-shell
    easyeffects pwvucontrol qpwgraph crosspipe
    appimage-run

    # 解压缩
    ouch      # 主力 Rust 万能解压
    _7zz      # 工业级 7-Zip 备用
    unar      # 乱码备用
    dtrx      # 智能防炸弹备用
  ];
}
