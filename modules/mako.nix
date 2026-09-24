{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    mako
    libnotify
  ];

  services.mako = {
    enable = true;
    
    # 将原来的属性全部放入 settings 中，并将驼峰命名法(camelCase)改为短横线命名法(kebab-case)
    settings = {
      # --- 位置与尺寸 ---
      anchor = "top-center";
      width = 350;
      height = 100;
      margin = "40,0,0,0";
      padding = "20";
      
      # --- 外观 ---
      border-size = 2;
      border-radius = 15;
      background-color = "#1E222AEE";
      border-color = "#4C566A";
      text-color = "#D8DEE9";
      
      # --- 时间 ---
      default-timeout = 15000;
    };

    # 注意：extraConfig 里的格式不需要改，因为它原本就是原生 mako 的语法
    extraConfig = ''
      [urgency=critical]
      border-color=#BF616A
      background-color=#2E3440EE
      text-color=#ECEFF4
      default-timeout=0
    '';
  };
}
