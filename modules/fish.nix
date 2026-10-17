{ pkgs, ... }:

{
  # 启用 Fish Shell 并在其中启用 Home Manager 管理
    programs.fish = {
    enable = true;

    # ⭐️ 必须套在 functions 这一层里面！
    functions = {
      cd = {
        description = "智能 cd：如果目標是檔案，自動進入其所在目錄";
        body = ''
          if test (count $argv) -eq 0
              builtin cd ~
              return
          end

          set -l target $argv[1]
          set target (string replace -r '^~' "$HOME" $target)

          if test -f "$target"
              builtin cd (path dirname "$target")
          else
              builtin cd $argv
          end
        '';
      };
    };
    };


  # 启用并配置 Starship 提示符（彻底解决路径缩写问题）
  programs.starship = {
    enable = true;
    # 允许在 Fish Shell 中自动加载 Starship
    enableFishIntegration = true; 
    
    settings = {
      # 核心修复：在这里定义路径的显示行为
      directory = {
        # 设为 0 代表无论路径多深，都绝不截断（显示最长完整路径）
        truncation_length = 0;
        # 设为 0 代表禁用类似 "~/e/nixos" 的缩写，强制显示完整的文件夹名字
        fish_style_pwd_dir_length = 0;
      };
    };
  };
}
