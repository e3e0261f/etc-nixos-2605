# /etc/nixos/modules/apps/apps-gui.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (discord.override {
      withOpenASAR = true;
    })
    helix gnupg wget curl unzip gh pstree iw
    procps lvm2 p7zip unrar parted gptfdisk
    dust pciutils scanmem alsa-utils keyd
    usbutils esptool espflash tio opensc
    mpv cloudflared killall mtr wrk
    xxd           # 十六進位/二進位互轉神兵（配 Helix 顯微鏡必備）
    binutils      # 包含 strings (吸取二進位中的文字) 與 readelf (解剖執行檔結構)
    file          # 看穿檔案本質、戳破偽裝的照妖鏡
    strace        # 系統呼叫監聽器，實時竊聽程式與 Linux 核心的底層對話
    lsof          # 查詢進程霸佔的文件、網卡、音效卡等硬體資源
    tcpdump       # 網卡原始封包無損監聽器，直接抓取流經網路的二進位原始碼
    pciutils      # lspci - 查詢主機板 PCI-E 匯流排與顯示卡底層硬體訊號
    usbutils      # lsusb - 查詢 USB 總線的底層硬體枚舉與連接訊號
    ethtool       # 直接控制、查詢物理網卡暫存器與底層線路狀態
    iotop         # 像 top 一樣，但專門實時監控是哪個進程在瘋狂操你的硬碟
    sysstat       # 包含 sar, iostat - 骨灰級系統效能與 CPU/記憶體底層瓶頸分析器

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
          libX11
          libXcursor
          libXi
          libXrandr

    
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
