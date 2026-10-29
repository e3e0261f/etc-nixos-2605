{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # --- 1. 隱私網絡與代理穿透 ---
    tor                       # 洋蔥路由暗網與本地 Socks5 匿名代理伺服器
    # cloudflared               # Cloudflare Tunnel 穿透與安全隧道客戶端

    # --- 2. 開發環境與遊戲平台主體 ---
    # vscodium                  # 完全去除微軟遙測的乾淨開源 VS Code
    # steam                     # 威爾福 Steam 遊戲平台本體
    # heroic                    # 開源 Epic / GOG 遊戲平台啟動器
    fontconfig

    # --- 3. 桌面動態渲染引擎 ---
    # linux-wallpaperengine     # 在 Linux 上運行 Wallpaper Engine 創意工坊壁紙的後台引擎
    mpvpaper                  # 將任意視頻作為 Wayland 動態壁紙的底層渲染器

    # --- 4. 大型命令列多執行緒下載器 ---

    # --- 5. 檔案系統輔助與可選桌面檔案管理器 ---
    nemo                      # 功能齊全的 Cinnamon 桌面檔案管理器
    # thunar                    # XFCE 輕量級檔案管理器
    # thunar-volman             # Thunar 可移動介質自動掛載管理插件
    # thunar-archive-plugin     # Thunar 右鍵壓縮包整合插件
    peazip                    # 支援超多冷門格式的高級圖形壓縮管理器

    # --- 6. 行動端、認證硬體與終端工具 ---
    # android-tools             # ADB 與 Fastboot 安卓調試工具集
    # libfido2                  # FIDO2 / WebAuthn 物理密鑰通訊庫
    # fido2-manage              # 物理安全密鑰管理與設定工具
    translate-shell           # 終端即時 Google/Bing 翻譯工具 (trans)

    # --- 7. 終端試算表 ---
    # sc-im                     # 終端裡帶有 Vim 快捷鍵的電子表格程式
    # sc                        # 經典 Unix 試算表計算器

    # --- 8. 客製化 FHS 隔離運行環境 ---
    (let base = pkgs.appimageTools.defaultFhsEnvArgs; in
      pkgs.buildFHSEnv (base // {
        name = "fhs";
        targetPkgs = pkgs: (base.targetPkgs pkgs) ++ (with pkgs; [
          pkg-config
          ncurses
        ]);
        profile = "export FHS=1";
        runScript = "bash";
        extraOutputsToInstall = ["dev"];
      })
    )
  ];

  # Bat 程式碼高亮檢視器配置
  programs.bat.enable = true;

  # Zoxide 智慧路徑跳轉 (自動注入 Fish)
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
