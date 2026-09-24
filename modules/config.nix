# /etc/nixos/modules/dev.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    helix
    git
    dae
    fish
    kitty
    # google-chrome
  ];
  imports =
    [ # Include the results of the hardware scan.
      ./nix-save.nix
      ./keyd.nix
      ./dae.nix
      # ./pipewire.nix
      # =======================================================
      # ⭐️ 軟體安裝分層控制中心（在新電腦上裝機時由上往下解封）
      # =======================================================
      # ./apps/apps-gui.nix    # ⭐️ 第 1 步解封：裝上瀏覽器與日常軟體
      # ./apps/apps-heavy.nix  # ⭐️ 第 2 步解封：裝上 Steam、VSCode 與 4K 桌布
      # ./apps/apps-sec.nix    # ⭐️ 第 3 步解封：後台慢慢拉取 40+ 滲透與編譯套件

      # ./hyprland.nix
      #./waybar.nix
      # ./openmega.nix
      # ./kitty.nix
      # ./tools.nix
      # ./helix.nix
      # ./git.nix
      # ./fcitx5.nix
      # ./mako.nix
      # ./fuzzel.nix
      # ./scripts.nix
      # ./copyfile.nix
      # ./yazi.nix
      # ./alarm.nix
      # ./awww.nix
      # ./defaults.nix   # ⭐️ 預設軟體設定 (Chrome, Nemo, Helix)
      # ./dev.nix        # ⭐️ Rust + JS 主力開發環境
      # ./rhys.nix
      # ./shell.nix
      # ./emacs.nix
    ];

  # nix.settings.substituters = [
  #   # CHina mirrors
  #   # "https://mirrors.ustc.edu.cn/nix-channels/store"
  #   # "https://mirror.sjtu.edu.cn/nix-channels/store"

  #   # nixos mirros
  #   "https://cache.nixos.org/"
  # ];
  # oOPen FLack on my nixos
  # nix.settings.experimental-features = [ "nix-command" "flakes" ];
    
  # UEfi token install error
  boot.loader.systemd-boot.graceful = true;
  # TAgs for start list
  system.nixos.tags = [ "no-luks" ];
  # ⭐️ 為 Chromium 啟用 Widevine DRM 模組
  nixpkgs.config.chromium.enableWideVine = true;
  # ⭐️ 讓 NixOS 完美相容並執行通用二進位程式與遊戲
  programs.nix-ld.enable = true;
  # ⭐️ 開啟遊戲全速效能調度
  programs.gamemode.enable = true;
}
