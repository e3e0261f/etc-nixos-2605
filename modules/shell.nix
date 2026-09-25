# /etc/nixos/modules/shell.nix (由 home.nix 引入的使用者級 Shell 核心配置)
{ pkgs, ... }:

{
  # =========================================================================
  # 🐟 1. 現代純血 Fish 核心配置
  # =========================================================================
  programs.fish = {
    enable = true;

    # === ⭐️ 現代四大神器 + 日常極客別名 ===
    shellAliases = {
      # 📁 1. eza 矩陣（取代傳統 ls，自帶圖標、目錄優先、Git 狀態）
      ls   = "eza --icons --group-directories-first";
      l    = "eza -l --icons --group-directories-first";
      ll   = "eza -la --icons --git --group-directories-first";
      la   = "eza -a --icons --group-directories-first";
      tree = "eza --tree --icons";
      lt   = "eza --tree --level=2 --icons";

      # 📖 2. bat 矩陣（取代傳統 cat，自帶語法高亮與行號）
      cat  = "bat --paging=never";
      catp = "bat -p";
      less = "bat";

      # 🔍 3. fd 矩陣（取代傳統 find，極速搜索）
      # find = "fd";
      # fda  = "fd -I -H";

      # ⚡ 4. ripgrep 矩陣（取代傳統 grep，全世界最快正則檢索）
      # grep = "rg";
      # rgi  = "rg -i";
      # rgf  = "rg --files";

      # 🛠️ 5. 其他極客日常縮寫
      top   = "btop";
      gcd   = "git clone --depth 1";
      helix = "hx";
      al    = "a -l";
      aa    = "a -a";
      as    = "a -s";
      cf    = "copyfile";
    };

    # === ⭐️ 轉換為標準 Fish 語法的自訂函數庫 ===
    functions = {
      # 1. 登出 / 關機
      logout = ''
        if command -v hyprshutdown >/dev/null 2>&1
          hyprshutdown
        else
          hyprctl dispatch 'hl.dsp.exit()'
        end
      '';

      # 2. 代理快速切換（直連 / 全域）
      proxy = ''
        if test (count $argv) -eq 0
          set -e http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
          echo "🌿 Proxy cleared. Mode: Direct"
        else
          set -gx http_proxy "http://127.0.0.1:$argv[1]"
          set -gx https_proxy "http://127.0.0.1:$argv[1]"
          set -gx all_proxy "socks5://127.0.0.1:$argv[1]"
          set -gx HTTP_PROXY "http://127.0.0.1:$argv[1]"
          set -gx HTTPS_PROXY "http://127.0.0.1:$argv[1]"
          set -gx ALL_PROXY "socks5://127.0.0.1:$argv[1]"
          echo "🌐 Proxy set to port $argv[1]. Mode: Global"
        end
      '';

      # 3. 一鍵選區定格截圖
      sss = ''
        set -l filename "$HOME/Pictures/"(date +%Y%m%d_%H%M%S)".png"
        mkdir -p "$HOME/Pictures"
        grim -g (slurp) "$filename"
        echo "📸 截圖已儲存至 $filename"
      '';

      # 4. OpenCC 繁簡字幕轉換與彩色比對
      cc = ''
        if test (count $argv) -eq 0
          set -l target_dirs "$HOME/下載" "$HOME/Downloads"
          set -l count 0
          for d in $target_dirs
            if test -d "$d"
              echo "🔍 正在掃描目錄: $d ..."
              for f in (find "$d" -type f -iname "*.srt")
                if string match -q "*.srt.txt" "$f"
                  continue
                end
                opencc -i "$f" -o "$f.txt" -c s2twp.json
                echo "✨ 轉繁成功: $f.txt"
                diff --color=always -u "$f" "$f.txt"
                set count (math $count + 1)
              end
            end
          end
          if test $count -eq 0
            echo "📭 沒有找到任何需要轉換的 .srt 檔案。"
          end
        else
          set -l f "$argv[1]"
          if test -f "$f"
            opencc -i "$f" -o "$f.txt" -c s2twp.json
            echo "✨ 單檔轉繁成功: $f.txt"
            diff --color=always -u "$f" "$f.txt"
          else
            echo "❌ 找不到檔案: $f"
          end
        end
        echo "🎉 所有轉換與對比搞定！"
      '';

      # ⭐️ 5. ouch 萬能極速解壓神技
      x = ''
        if test (count $argv) -eq 0
          echo "用法: x <壓縮包檔案>"
          return 1
        end
        ouch d $argv
      '';
    };

    # === ⭐️ 啟動環境變數注入 ===
    interactiveShellInit = ''
      # GPG SSH Agent 代理
      set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
    '';
  };

  # =========================================================================
  # 🚀 2. 終端神級輔助插件 (修正為 Fish 整合)
  # =========================================================================

  # 智能目錄跳躍 zoxide (z 命令)
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true; # ⭐️ 改為 Fish 整合
  };

  # 跨終端極速提示符 Starship
  programs.starship = {
    enable = true;
    enableFishIntegration = true; # ⭐️ 改為 Fish 整合
  };

  # =========================================================================
  # 🧰 3. 使用者級別必備工具鏈
  # =========================================================================
  home.packages = with pkgs; [
    eza         # 現代版 ls
    bat         # 现代版 cat
    fd          # 現代版 find
    ripgrep     # 現代版 grep
    btop        # 現代任務管理器
    opencc      # 字幕繁簡轉換
    diffutils   # 彩色 diff
    ouch        # ⭐️ 萬能極速解壓神器 (支援 x 指令)
  ];
}
