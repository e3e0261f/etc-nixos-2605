{ pkgs, ... }:

{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        # --- 核心显示设置 ---
        monitor = 0;
        follow = "mouse";
        width = 400;
        height = 300;
        origin = "top-right";
        offset = "20x50";
        scale = 0;
        notification_limit = 5; # 限制显示数量，避免屏幕被刷屏
        
        # --- 文本处理 (关键：解决长路径挤爆问题) ---
        word_wrap = "yes";       # 自动换行
        format = "<b>%s</b>\n%b"; # 标题加粗\n内容
        markup = "full";         # 支持 pango 标记
        
        # --- 外观 ---
        frame_width = 2;
        frame_color = "#88C0D0";
        separator_color = "frame";
        padding = 15;
        horizontal_padding = 15;
        font = "JetBrainsMono Nerd Font 12";
        
        # --- 交互 ---
        mouse_left_click = "close_current"; # 左键点击关闭
        mouse_right_click = "close_all";    # 右键点击关闭所有
      };

      # 针对严重错误的样式
      urgency_critical = {
        background = "#3B4252";
        foreground = "#ECEFF4";
        frame_color = "#BF616A";
        timeout = 0; # 严重错误常驻，直到你手动关闭
      };
    };
  };
}
