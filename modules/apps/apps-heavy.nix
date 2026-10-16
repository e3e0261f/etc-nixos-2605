{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # --- 1. 開發環境與遊戲平台主體 ---
    vscodium                  # 完全去除微軟遙測的乾淨開源 VS Code
    steam                     # 威爾福 Steam 遊戲平台本體
    heroic                    # 開源 Epic / GOG 遊戲平台啟動器

    # --- 2. 桌面動態渲染引擎 ---
    linux-wallpaperengine     # 在 Linux 上運行 Wallpaper Engine 創意工坊壁紙的後台引擎
    mpvpaper                  # 將任意視頻作為 Wayland 動態壁紙的底層渲染器
    mpv                       # 萬能極簡極客播放器 (也是終端相簿！)

    # --- 3. 大型命令列多執行緒下載器 ---
    aria2                     # 輕量級多協議、多執行緒命令列下載神兵
    axel                      # 極度精簡迅速的 HTTP/FTP 下載加速器

    # --- 4. 檔案系統輔助與檔案管理器插件 ---
    nemo                      # 功能齊全的 Cinnamon 桌面檔案管理器
    thunar                    # XFCE 輕量級檔案管理器
    thunar-volman             # Thunar 可移動介質自動掛載管理插件
    thunar-archive-plugin     # Thunar 右鍵壓縮包整合插件
    peazip                    # 支援超多冷門格式的高級圖形壓縮管理器

    # --- 5. 現代高頻 Rust 命令列工具全家桶 ---
    ripgrep                   # rg - 極速程式碼遞迴搜尋工具
    fd                        # 簡潔、符合直覺的 find 現代替代品
    eza                       # 帶圖示、Git 狀態與顏色的現代 ls 替代品

    # --- 6. 行動端、認證硬體與終端工具 ---
    android-tools             # ADB 與 Fastboot 安卓調試工具集
    libfido2                  # FIDO2 / WebAuthn 物理密鑰通訊庫
    fido2-manage              # 物理安全密鑰管理與設定工具
    bind                      # DNS 查詢工具集 (包含 dig, nslookup)
    gnupg                     # GPG 密鑰生成與文字簽名加密工具
    wget                      # 傳統非互動式網路檔案下載器
    curl                      # 萬能命令列網路傳輸工具
    translate-shell           # 終端即時 Google/Bing 翻譯工具 (trans)

    # --- 7. 終端命令列計算器套件 ---
    sc-im                     # 終端裡帶有 Vim 快捷鍵的電子表格程式
    sc                        # 經典 Unix 試算表計算器
    bc                        # 經典任意精度數值計算語言
    calc                      # 互動式 C 風格高級任意精度計算器

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
