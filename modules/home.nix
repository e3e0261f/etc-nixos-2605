{ pkgs, inputs, ... }:

{
  # 🎯 這裡成了唯一的「插線板 / 總路由」
  imports = [
    ./hyprland.nix
    #./waybar.nix
    ./openmega.nix
    ./kitty.nix
    ./tools.nix
    ./helix.nix
    ./git.nix
    ./fcitx5.nix
    ./mako.nix
    ./fuzzel.nix
    ./scripts.nix
    ./copyfile.nix
    ./yazi.nix
    ./alarm.nix
    ./wall-random.nix
    ./defaults.nix   # ⭐️ 預設軟體設定 (Chrome, Nemo, Helix)
    ./dev.nix        # ⭐️ Rust + JS 主力開發環境
    ./rhys.nix
    ./shell.nix
    # ./emacs.nix
  ];

  home.sessionVariables = {
    # 這是所有 GTK 程式 (包含你彈出的通知、輸入法設定) 的字體大小總開關
    GTK_FONT_NAME = "Noto Sans CJK TC 16";
  };

  # 💡 確保 Waybar 由 Systemd 管理，並掛載在 Hyprland 會話上
  # programs.waybar = {
  #   enable = true;
  #   systemd = {
  #     enable = true;
  #     targets = [ "hyprland-session.target" ];
  #   };
  # };
  #
    # 1. 在软件包列表中：使用 with-cli，并把命令行工具也加进终端
  home.packages = with pkgs; [
    inputs.caelestia-shell.packages.${pkgs.system}.with-cli # ⭐️ 改为 with-cli
    inputs.caelestia-cli.packages.${pkgs.system}.default    # ⭐️ 终端直接可用的 caelestia 命令
    inputs.quickshell.packages.${pkgs.system}.default
    # ... 你原来的其他包
  ];

  # 2. 在 Systemd 守护进程中：同样指向 with-cli
  systemd.user.services.caelestia-shell = {
    Unit = {
      Description = "Caelestia Desktop Shell Daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Environment = [ "QS_ICON_THEME=Papirus-Dark" ];
      # ⭐️ 同样换成 with-cli
      ExecStart = "${inputs.caelestia-shell.packages.${pkgs.system}.with-cli}/bin/caelestia-shell";
      Restart = "on-failure";
      RestartSec = "1s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # 💡 IBus 服務託管
  systemd.user.services.ibus-daemon = {
    Unit = {
      Description = "IBus Input Method Daemon";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = {
      ExecStart = "${pkgs.ibus}/bin/ibus-daemon -drx --panel disable";
      Restart = "on-failure";
    };
  };

  # 💡 網路圖示託管
  systemd.user.services.nm-applet = {
    Unit = {
      Description = "Network Manager Applet";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = {
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      Restart = "on-failure";
    };
  };

  # 只有版本號留在此處
  home.stateVersion = "24.11";
}
