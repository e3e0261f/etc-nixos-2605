{ pkgs, inputs, ... }:

{
  # 🎯 這裡成了唯一的「插線板 / 總路由」
  imports = [
        # -----------------------------------------------------------------------
    # 🖥️ 1. 桌面環境、外觀與視窗管理 (Hyprland / Shell)
    # -----------------------------------------------------------------------
    ./hyprland.nix      # 🪟 Hyprland 核心設定 (平鋪規則、動畫、毛玻璃、Caelestia drawers 快捷鍵)
    #./waybar.nix       # 📊 [歷史備用] 原版 3D 水晶毛玻璃狀態列 (目前已由 Caelestia Shell 接管)
    ./wall-random.nix   # 🖼️ 桌布輪播引擎 (Wallhaven 隨機抽 2K/4K 桌布盲盒，60FPS 轉場特效)
    ./mako.nix          # 🔔 輕量級桌面通知守護進程 (Mako Notification Daemon)
    ./fuzzel.nix        # 🔍 輕量 Wayland 應用程式搜尋與啟動器 (Fuzzel dmenu/rofi 替代品)

    # -----------------------------------------------------------------------
    # ⌨️ 2. 輸入法、終端機與主力編輯器 (Terminal & Productivity)
    # -----------------------------------------------------------------------
    ./fcitx5.nix        # ⌨️ Fcitx5 輸入法 (Rime 中州韻 + 小鶴雙拼 + 四葉草詞庫 + 八股文語意模型)
    ./kitty.nix         # 🐱 Kitty GPU 加速終端機 (JetBrainsMono 字體、透明背景、按鍵穿透)
    ./helix.nix         # 🧬 Helix 現代模態編輯器 (Space+w 存檔 | Space+Space 搜檔 | LSP 自動補全)
    ./yazi.nix          # 📁 Yazi 終端檔案管理器 (g D 一秒跳 ~/DOwn，Enter 直連 Helix，極速預覽)
    ./defaults.nix      # 🌐 全域預設應用程式關聯 (預設 Chrome、檔案管理 Nemo、播放器 VLC)

    # -----------------------------------------------------------------------
    # 🛠️ 3. 程式開發、版本控制與常用工具 (Dev & CLI Tools)
    # -----------------------------------------------------------------------
    ./dev.nix           # 🦀 核心開發鏈 (Rust/Cargo + Node.js 22/pnpm/Bun/Biome 雙主力環境)
    ./git.nix           # 🐙 Git 版本控制 (全域郵箱、使用者名稱、Delta 語法高亮、簽名配置)
    ./tools.nix         # 🧰 系統常用 CLI 瑞士軍刀小工具 (ripgrep, fd, bat, eza, fzf 等)
    ./shell.nix         # 🐟 Fish Shell 設定 (命令別名 alias、自訂環境變數、終端行為優化)
    # ./emacs.nix       # 🦄 [已停用備份] Emacs 編輯器設定

    # -----------------------------------------------------------------------
    # 🚀 4. 自製極客腳本、生活智慧與系統百科 (Custom Hacks & Tools)
    # -----------------------------------------------------------------------
    ./rhys.nix          # 📖 專屬全系統極客百科 (rhys -h 查快捷鍵 | rhys -t 工具箱 | rhys -r 斷網救急)
    ./scripts.nix       # 📸 自訂快速指令集 (Super+Ctrl+S 凍結截圖、record-screen 錄影、即時翻譯)
    ./copyfile.nix      # 📋 CLI 複製實體檔案進 Wayland 剪貼簿 (支援改名複製，可在瀏覽器/Dolphin直接貼上)
    ./alarm.nix         # ⏰ 智慧定時鬧鐘與紀念日 (remind 指令預約 + 內建 17KB 6kg.xm 晶片音樂)
    ./openmega.nix      # ☁️ MEGA 網盤雲端同步與專屬下載加速工具
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
