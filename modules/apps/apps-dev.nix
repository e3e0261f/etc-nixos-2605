{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # --- 1. Rust 完整開發工具鏈與 WASM 構建 ---
    rustc                     # Rust 語言編譯器本體
    cargo                     # Rust 官方套件管理器與建構工具
    clippy                    # Rust 程式碼規範與潛在 Bug 靜態分析器
    rustfmt                   # Rust 程式碼自動格式化工具
    trunk                     # WASM 前端專案打包與熱重載伺服器
    wasm-bindgen-cli          # Rust 轉譯 WebAssembly 黏合代碼生成 CLI
    lld                       # LLVM 旗下的極速現代鏈接器

    # --- 2. C/C++ 與底層建構工具鏈 ---
    gcc                       # GNU C/C++ 編譯器套裝
    gnumake                   # Make 專案建構工具
    ninja                     # 極速小型編譯構建系統
    libtool                   # 通用庫支援腳本
    pkg-config                # 自動檢測並提供庫編譯參數的工具
    glibc                     # GNU C 核心執行庫
    libgcc                    # GCC 基礎執行時支援庫

    # --- 3. 跨語言開發環境與輔助 ---
    devbox                    # 基於 Nix 的便攜式隔離開發環境
    ruby                      # Ruby 解釋器
    luajit                    # 極速 Lua 即時編譯器
    tsx                       # TypeScript 增強執行環境
    opencc                    # 開源中文繁簡體轉換工具庫
    wev                       # Wayland 鍵盤按鍵與滑鼠事件即時檢測器

    # --- 4. 系統底層圖形與輸入協議依賴 (GUI 開發必備) ---
    libxkbcommon              # 鍵盤按鍵映射與合成解析庫
    libGL                     # OpenGL 核心渲染規範支援庫
    wayland                   # Wayland 通訊協定底層核心庫
    libX11                    # X11 基礎協議客戶端庫
    libXcursor                # X11 游標管理庫
    libXi                     # X11 輸入擴展庫 (XInput)
    libXrandr                 # X11 螢幕動態解析度擴展庫
    glib                      # GNOME 跨平台底層核心 C 函數庫

    # --- 5. 嵌入式硬體開發燒錄套裝 ---
    esptool                   # 樂鑫 ESP8266/ESP32 系列晶片 ROM 燒錄工具
    espflash                  # 現代 Rust 撰寫的 ESP32 高速燒錄器
    tio                       # 專注於硬體除錯的終端序列埠 (Serial) 工具
  ];
}
