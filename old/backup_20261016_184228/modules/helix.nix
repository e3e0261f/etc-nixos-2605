{ pkgs, ... }:

{
  programs.helix = {
    enable = true;

    # 外部 CLI 工具依賴
    extraPackages = with pkgs; [
      ripgrep       # 全域搜尋 (Space + /)
      fd            # 快速檔案搜尋 (Space + f)
      wl-clipboard  # Wayland 系統剪貼簿
      lldb          # 提供 lldb-dap 除錯器

      #HX 编辑器支援
      nil nixfmt taplo
      bash-language-server shellcheck
      lua-language-server marksman
      yaml-language-server
      rust-analyzer pyright
      gopls clang-tools

    ];

    settings = {
      theme = "tokyonight";

      editor = {
        line-number = "relative"; # 相對行號
        cursorline = true;        # 高亮當前行
        color-modes = true;       # 狀態列顏色隨模式改變
        bufferline = "multiple";  # 頂部顯示分頁 (Tabs)
        # 开启自动换行
        soft-wrap.enable = true;

        # (可选) 让换行后的文本在视觉上保持与上一行相同的缩进
        soft-wrap.wrap-at-text-width = false;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        # 寫 Rust 必備：內聯型別提示
        lsp = {
          display-inlay-hints = true;
          display-messages = true;
        };

        # 側邊欄（Git 改動與錯誤）
        gutters = {
          layout = [ "diff" "diagnostics" "line-numbers" "spacer" ];
        };

        # 底部狀態列自訂
        statusline = {
          left = [ "mode" "spinner" "file-name" "read-only-indicator" "file-modification-indicator" ];
          right = [ "diagnostics" "selections" "position" "file-encoding" "version-control" ];
        };
      };

      # ==========================================
      # 快捷鍵設定（Normal 與 Select 平級分開）
      # ==========================================
      
      # 1. 普通模式 (Normal Mode)
      keys.normal = {
        "C-S-c" = "yank_joined_to_clipboard";  # Ctrl + Shift + C 複製
        "C-s" = ":w";                          # Ctrl + s 保存
        "y" = "yank_joined_to_clipboard";      # y 複製到系統剪貼簿
        "p" = "paste_clipboard_after";         # p 貼上系統剪貼簿
        "P" = "paste_clipboard_before";        # P 貼上系統剪貼簿到前方
        "C-c" = "toggle_comments";             # Ctrl + c 切換註解

        # Space 領導者選單
        space = {
          space = "file_picker";  # 兩次 Space 開啟檔案搜尋
          w = ":w";               # Space + w 快速存檔
          z = ":x";               # Space + z 存檔並退出
          x = ":q!";              # Space + x 不存檔退出
        };
      };

      # 2. 選取模式 (Select Mode) - 獨立區塊，絕對不與 normal 混雜
      keys.select = {
        "C-S-c" = "yank_joined_to_clipboard";  # 選中文字後按 Ctrl + Shift + C 複製
      };
    };
  };
}
