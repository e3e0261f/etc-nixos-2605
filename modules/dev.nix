# /etc/nixos/modules/dev.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # =====================================================
    # 🦀 1. Rust 主力開發鏈 (Rust Toolchain)
    # =====================================================
    rustc                   # Rust 編譯器
    cargo                   # Rust 套件管理器
    rust-analyzer           # ⭐️ Rust 語言伺服器 (Helix 自動補全、型別推導核心)
    clippy                  # Rust 靜態代碼分析與最佳化建議
    rustfmt                 # 官方代碼排版工具
    cargo-edit              # 命令行快速新增依賴 (cargo add / cargo rm)
    cargo-watch             # 檔案變動自動編譯測試

    # =====================================================
    # 🌐 2. JavaScript / TypeScript 開發鏈 (JS/TS Ecosystem)
    # =====================================================
    nodejs_22               # 當前最新 LTS 版 Node.js 執行環境
    pnpm                    # 現代極速、節省硬碟空間的 JS 套件管理器
    bun                     # 用 Zig 寫的超快 JS/TS 運行時與打包工具
    typescript              # TypeScript 編譯器 (tsc)
    typescript-language-server # ⭐️ JS/TS 語言伺服器 (Helix 的 JS 自動補全大腦)
    biome                   # ⭐️ 純 Rust 寫的超快 JS/TS 語法檢查與格式化工具 (秒殺 Prettier/ESLint)
  ];
}
