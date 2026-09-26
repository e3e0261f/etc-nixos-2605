# /etc/nixos/modules/dev.nix
# git clone https://gist.github.com/e3e0261f/951488c7b640b599b33c1aec6bc4399b
# git clone https://github.com/e3e0261f/etc-nixos-2605.git
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    # a command install
    inputs.a-cli.packages.${pkgs.system}.default
    helix git dae fish kitty
  ];
  imports =
    [ # Include the results of the hardware scan.
      ./nix-save.nix
      ./keyd.nix
      ./dae.nix
      ./pipewire.nix
      ./fonts.nix
      ./login.nix
      # =======================================================
      # ⭐️ 軟體安裝分層控制中心（在新電腦上裝機時由上往下解封）
      # =======================================================
      ./apps/apps-base.nix
      ./apps/apps-gui.nix    # ⭐️ 第 1 步解封：裝上瀏覽器與日常軟體
      ./apps/apps-heavy.nix  # ⭐️ 第 2 步解封：裝上 Steam、VSCode 與 4K 桌布
      ./apps/apps-sec.nix    # ⭐️ 第 3 步解封：後台慢慢拉取 40+ 滲透與編譯套件
    ];

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
  
  # 睡眠唤醒解耦
  powerManagement = {
    enable = true;
    powerDownCommands = ''
      /run/current-system/sw/bin/modprobe -r mt7925e || true
    '';
    resumeCommands = ''
      /run/current-system/sw/bin/sleep 2
      /run/current-system/sw/bin/modprobe mt7925e || true
      /run/current-system/sw/bin/systemctl restart NetworkManager
      /run/current-system/sw/bin/sleep 1
      # ⭐️ 核心解藥：網卡重載完成後，立即命令 dae 重新掛載 eBPF 探針！
      /run/current-system/sw/bin/systemctl stop dae
      /run/current-system/sw/bin/systemctl start dae
    '';
  };

  # --- 1. 核心與驅動 ---
  # boot.kernelPackages = pkgs.linuxPackages_zen;
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # 降低延遲核心依賴
  security.rtkit.enable = true;

  # 藍牙支援
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # 啟用智慧卡支援
  services.pcscd.enable = true;
  hardware.gpgSmartcards.enable = true;

  # ⭐️ 啟用純記憶體壓縮 Swap (zram)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # 載入 BBR 核心模組
  boot.kernelModules = [ "tcp_bbr" ];

  # --- 3. 系統核心與 Nix 設定 ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ 
      "https://mirrors.cernet.edu.cn/nix-channels/store" 
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors4.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://quickshell.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "quickshell.cachix.org-1:rRtHdQalhkLqlygtlhOOtwBh2hyuhflHVu5ROCeuZK4="
    ];

    max-jobs = "auto";
    cores = 0; 
    http-connections = 50; 
    min-free = 128000000;
    auto-optimise-store = true;
    trusted-users = [ "root" "rhys" ];
  };


  # TCP / 網路堆疊調優
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_fin_timeout" = 15;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };
  
  environment.sessionVariables = {
    XDG_DATA_DIRS = [
      "/run/current-system/sw/share"
      "/etc/profiles/per-user/rhys/share"
      "/home/rhys/.nix-profile/share"
      "/home/rhys/.local/share"
    ];
    LANGUAGE = "zh_TW:zh_CN:zh:en";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11,*";
    ANKI_WAYLAND = "1";
    DIRENV_LOG_FORMAT = "";
    QS_ICON_THEME = "Papirus-Dark";
  };
  
  # Fcitx5 輸入法
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      fcitx5-rime
      qt6Packages.fcitx5-chinese-addons
      fcitx5-nord
      kdePackages.fcitx5-qt
    ];
  };
  
  # --- 7. 使用者與 Git 設定 ---
  users.users."rhys" = {
    isNormalUser = true;
    description = "Rhys";
    extraGroups = [ "networkmanager" "wheel" "storage" "video" "render" "audio" "adbusers" ];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  services.udisks2.enable = true;
  security.polkit.enable = true;
  services.printing.enable = true;
  # services.flatpak.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true; 
  
  # --- 網路與系統服務 ---
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    connectionConfig = {
      "ipv4.route-metric" = 100;
      "ipv6.route-metric" = 100;
    };
  };

  # oOPen FLack on my nixos
  # nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # HYprland 
  programs = {
  hyprland.enable = true;
  hyprlock.enable = true;
  hyprland.withUWSM = true;
  hyprland.xwayland.enable = true;
  };
  # 自动休眠
  services.hypridle.enable = true;
  # ⭐️ 強制關閉 Wi-Fi 晶片省電
  networking.networkmanager.wifi.powersave = false;
  # UEfi token install error
  boot.loader.systemd-boot.graceful = true;
  # ⭐️ 為 Chromium 啟用 Widevine DRM 模組
  nixpkgs.config.chromium.enableWideVine = true;
  # ⭐️ 讓 NixOS 完美相容並執行通用二進位程式與遊戲
  programs.nix-ld.enable = true;
  # ⭐️ 開啟遊戲全速效能調度
  programs.gamemode.enable = true;
  # TAgs for start list
  system.nixos.tags = [ "LOgin" ];
}
