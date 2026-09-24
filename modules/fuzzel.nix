{ pkgs, ... }:

{
  # 确保安装了 fuzzel
  home.packages = with pkgs; [
    fuzzel
  ];

  programs.fuzzel = {
    enable = true;
    
    settings = {
      main = {
        # 终端启动命令 (Hyprland 下通常这样)
        terminal = "${pkgs.foot}/bin/foot";
        # 字体
        font = "FiraCode Nerd Font:size=12";
        # 居中显示
        anchor = "center";
        # 宽度
        width = 40;
        # 列表条目数
        lines = 8;
        # 边框宽度
        border-width = 2;
        # 圆角
        border-radius = 10;
        # 内边距
        padding = "20x20";
        # 输入框占位符
        placeholder = "搜索应用...";
      };

      colors = {
        # 颜色方案 (Nord 风格)
        background = "2E3440FF";
        text = "D8DEE9FF";
        match = "88C0D0FF";
        selection = "4C566AFF";
        selection-text = "ECEFF4FF";
        border = "88C0D0FF";
      };

      border = {
        width = 2;
        radius = 10;
      };
    };
  };
}
