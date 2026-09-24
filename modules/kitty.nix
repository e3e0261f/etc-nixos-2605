{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    
    # ⭐️ 1. 字體設定（在這裡統一設定即可，不需要在 settings 裡重複寫）
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 24; # 字體大小 24
    };

    settings = {
      background_opacity = "0.65";
      window_padding_width = 10;
      # ⭐️ 滑鼠反白選取文字時自動進剪貼簿，終端機日常完全不需要按鍵複製
      copy_on_select = "clipboard";
    };

    keybindings = {
      # ⭐️ 核心解鎖：禁止 Kitty 攔截 Ctrl+Shift+C，把它原封不動放行傳遞給內部的 Helix！
      "ctrl+shift+c" = "no_op";
      
      # 終端貼上依然保留
      "ctrl+shift+v" = "paste_from_clipboard";
    };
  };
}
