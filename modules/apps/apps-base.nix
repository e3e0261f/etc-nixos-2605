{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # --- 1. 核心編輯器與 Shell 環境 ---
    helix                     # 現代終端模態純文字編輯器 (hx)
    bash                      # GNU 標準 Bash
    fish                      # 現代化互動式 Fish Shell
    zsh                       # Z Shell 解釋器

    # --- 2. 系統資訊、核心與進程探針 (Top / PS / 樹狀圖) ---
    procps                    # 核心進程管理工具集 (ps, top, free, sysctl)
    killall                   # 依程式名稱批量殺死進程
    pstree                    # 樹狀圖層級展示所有父子進程
    file                      # 看穿檔案本質的照妖鏡
    binutils                  # strings 與 readelf 二進位剖析工具集
    xxd                       # 十六進位/二進位互轉工具 (顯微鏡必備)
    iotop                     # 實時監控各進程硬碟 I/O 讀寫頻寬
    sysstat                   # 包含 sar, iostat 等底層效能瓶頸採集套件

    # --- 3. 網路診斷、底層硬體與通訊工具 ---
    networkmanager            # 網路連線管理主程式與 nmcli
    iw                        # Linux 官方底層無線網卡配置工具
    ethtool                   # 物理網卡硬體狀態、速率與暫存器診斷
    lsof                      # 查詢特定文件/連接埠被哪些進程霸佔
    mtr                       # 結合 ping 與 traceroute 的全動態路由追蹤器
    alsa-utils                # ALSA 底層音訊除錯工具 (aplay, amixer)
    pciutils                  # lspci - PCI-E 匯流排與顯卡硬體拓撲查詢
    usbutils                  # lsusb - 物理 USB 總線硬體枚舉與狀態查詢
    keyd                      # 系統底層鍵盤映射重定義守護進程
    opensc                    # 智慧卡 (SmartCard) 與硬體密鑰 (Yubikey) 支援庫
    lm_sensors                # CPU/主機板溫度與風扇轉速感測器
    power-profiles-daemon     # 系統電源效能模式切換守護進程
    brightnessctl             # 螢幕背光硬體調節工具
    ddcutil                   # 透過 DDC/CI 協議調節外接顯示器硬體亮度

    # --- 4. 磁碟分割與容量分析 ---
    parted                    # 命令列動態磁碟分區調整工具
    gptfdisk                  # gdisk - GUID 分區表 (GPT) 專用進階維護工具
    lvm2                      # 邏輯捲軸管理工具 (LVM)
    dust                      # 終端可視化目錄硬碟空間佔用分析 (du 的現代替代品)

    # --- 5. 萬能解壓縮工具全家桶 ---
    ouch                      # 主力 Rust 萬能解壓縮工具 (極速且智慧識別格式)
    _7zz                      # 官方最新 7-Zip 完整單獨執行檔
    p7zip                     # 經典 POSIX 移植版 7z 工具
    unzip                     # 傳統 ZIP 解壓縮工具
    unrar                     # 專用 RAR 格式提取工具
    unar                      # 處理舊 Windows 壓縮包編碼亂碼的救星
    dtrx                      # 智慧解壓縮工具 (自動包裝資料夾，防止壓縮包炸彈)

    # --- 6. Rust 核心開發鏈與 WASM 構建 (基礎工具) ---
    rustc                     # Rust 語言編譯器本體
    cargo                     # Rust 官方套件管理器與建構工具
    clippy                    # Rust 程式碼規範與潛在 Bug 靜態分析器
    rustfmt                   # Rust 程式碼自動格式化工具
    trunk                     # WASM 前端專案打包與熱重載伺服器
    wasm-bindgen-cli          # Rust 轉譯 WebAssembly 黏合代碼生成 CLI
    lld                       # LLVM 旗下的極速現代鏈接器

    # --- 7. 音訊控制、路由與視覺化 ---
    pamixer                   # 終端 PulseAudio/PipeWire 音量控制
    playerctl                 # 多媒體播放控制 CLI (支援鍵盤切歌/暫停)
    pwvucontrol               # 基於 GTK 的 PipeWire 音量混音器
    qpwgraph                  # 節點式 PipeWire 音訊/MIDI 補丁連接圖
    crosspipe                 # PipeWire 跨設備音訊橋接轉發工具
    easyeffects               # PipeWire 系統級音效等化器與降噪處理器
    libcava                   # 音訊可視化 CAVA 核心共享庫
    aubio                     # 音訊特徵提取與音高/節拍分析庫

    # --- 8. 桌面環境基礎組件 (Hyprland 生態支援) ---
    hyprlauncher              # 應用程式啟動器
    hyprshutdown              # 關機/重啟控制腳本
    wlogout                   # 圖形化登出/鎖定/關機選單
    hyprpaper                 # 壁紙渲染守護進程
    hyprpicker                # 螢幕顏色吸管工具
    swappy                    # 截圖即時標註與編輯工具
    wl-clipboard              # Wayland 原生剪貼簿工具 (wl-copy / wl-paste)
    grim                      # Wayland 原生截圖核心抓取工具
    slurp                     # Wayland 區域螢幕選取框工具
    libqalculate              # 終端全能高精度計算器庫
    appimage-run              # 直接執行通用 Linux AppImage 的黑魔法

    # --- 9. 核心字體與圖示主題 ---
    material-symbols          # Google Material 符號圖示字型
    rubik                     # 現代幾何無襯線字型
    cascadia-code             # 微軟高質感終端程式碼字型 (支援連字)
    papirus-icon-theme        # 扁平化現代開源圖示主題
    qt6.qtbase                # Qt6 基礎圖形庫核心
    qt6.qtimageformats        # Qt6 額外圖像格式支援插件
    qt6.qtdeclarative         # Qt6 QML/Quick 動態介面引擎
    qt6.qtshadertools         # Qt6 著色器轉換與渲染工具
  ];
}
