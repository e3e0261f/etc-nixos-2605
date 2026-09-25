{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    mako
    libnotify
  ];

  services.mako = {
    enable = true;
    
    settings = {
      # --- 关键：取消固定 height，改为使用最小高度和最大高度 ---
      # 这样 mako 就会根据内容自动拉伸
      height = 200;            # 最小高度
      max-visible = 3;         # 最多同时显示 3 条，避免刷屏
      
      # --- 布局 ---
      anchor = "top-right";    # 个人建议改到右上角，更符合系统习惯
      width = 450;             # 适当增加宽度，容纳较长的文本
      margin = "20";
      padding = "15";
      
      # --- 文本处理 ---
      # 开启 word wrap，这能让长文本在宽度内自动换行而不是单行显示
      text-alignment = "left";
      markup = true;           # 开启 Pango 标记支持
      format = "<b>%s</b>\n%b"; # 标题加粗，下面显示详细内容
      
      # --- 外观 ---
      border-size = 2;
      border-radius = 10;
      background-color = "#2E3440F0"; 
      border-color = "#88C0D0";
      text-color = "#D8DEE9";
      
      # --- 逻辑 ---
      default-timeout = 8000;  # 8秒通常足够阅读了
      sort = "-time";          # 新的在上面
    };

    extraConfig = ''
      [urgency=critical]
      border-color=#BF616A
      background-color=#3B4252F0
      text-color=#ECEFF4
      default-timeout=0        # 严重错误不自动消失，需手动点击清除
    '';
  };
}
