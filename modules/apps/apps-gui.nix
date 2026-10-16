{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # --- 1. 瀏覽器與通訊 ---
    google-chrome             # Google Chrome 穩定版瀏覽器
    (discord.override {
      withOpenASAR = true;
    })                        # 注入 OpenASAR 輕量優化補丁的 Discord 客戶端

    # --- 2. 密碼、隱私與安全 ---
    keepassxc                 # 本地強加密密碼管理器
    tor                       # 洋蔥路由暗網與匿名代理伺服器
    clash-verge-rev           # 基於 Tauri 的現代代理核心圖形客戶端

    # --- 3. 專業音訊、剪輯與創作工作站 ---
    reaper                    # 專業級數位音訊工作站 (DAW)
    tenacity                  # 乾淨無隱私追蹤的 Audacity 純開源繼承者
    losslesscut               # 基於 FFmpeg 的無損音視頻極速剪切工具
    gimp                      # GNU 旗艦級開源點陣圖像處理軟體

    # --- 4. 遊戲設計、地圖編輯與娛樂 ---
    tiled                     # 經典靈活的 2D 瓦片地圖編輯器
    ldtk                      # 現代靈動的 2D 關卡設計器 (Level Designer)
    steam-run                 # 在 NixOS 上模擬標準 FHS 運行任意閉源二進位的神器
    sl                        # 治癒手滑敲錯 ls 的蒸汽車頭動畫

    # --- 5. 圖片檢視、OCR 與翻譯 ---
    loupe                     # GNOME 現代簡潔硬體加速圖片檢視器
    waypaper                  # 基於 GUI 的 Wayland 動態壁紙前端切換器
    gimagereader              # Tesseract OCR 圖形化前端
    tesseract                 # 開源多國語言光學字元識別 (OCR) 引擎
    crow-translate            # 基於 Qt 的螢幕選詞即時翻譯工具

    # --- 6. 檔案管理與操作增強 ---
    pcmanfm-qt                # 極度輕量迅速的 Qt 檔案管理器
    wl-kbptr                  # Wayland 下完全用鍵盤代替滑鼠指針操作的神器

    # --- 7. 虛擬化平台與遠端桌面 (Windows 虛擬機套件) ---
    virt-manager              # KVM/QEMU 虛擬機圖形化管理面板
    virt-viewer               # 虛擬機圖形控制台客戶端
    spice                     # SPICE 虛擬化通訊協議核心庫
    spice-gtk                 # SPICE 協議的 GTK 圖形客戶端組件
    freerdp                   # 現代高效的 RDP 遠端桌面協定客戶端
  ];

  # Hyprland 桌面會話與入口
  programs.hyprland = {
    enable = true;
  };
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

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
}
