{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    
    # ⭐️ 1. 字體設定
    font = {
      name = "SFMono Nerd Font";
      size = 16;
    };

    settings = {
      confirm_os_window_close = 0;
      background_opacity = "0.65";
      window_padding_width = 10;
      copy_on_select = "clipboard";

      # ⭐️ 新增：直接指定使用 Google Chrome 打开链接
      open_url_with = "google-chrome-stable";
    };

    keybindings = {
      "ctrl+shift+c" = "no_op";
      "ctrl+shift+v" = "paste_from_clipboard";
    };
  };
}
