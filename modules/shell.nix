# shell.nix (由 home.nix 引入的使用者級 Shell 核心配置)
{ pkgs, ... }:

{
  # 1. ⭐️ Zsh 核心功能、神級插件與歷史調教
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;     # 灰字幽靈預測 (按 → 鍵補全)
    syntaxHighlighting.enable = true; # 即時語法高亮 (打對變綠，打錯變紅)

    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.zsh_history";
      ignoreAllDups = true;
      share = true;
    };

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
      find = "fd";
      fda  = "fd -I -H";

      # ⚡ 4. ripgrep 矩陣（取代傳統 grep，全世界最快正則檢索）
      grep = "rg";
      rgi  = "rg -i";
      rgf  = "rg --files";

      # 🛠️ 5. 其他極客日常縮寫
      top   = "btop";
      gcd   = "git clone --depth 1";
      helix = "hx";
      al    = "a -l";
      aa    = "a -a";
      as    = "a -s";
      em    = "emacs -nw";
    };

    # === ⭐️ 使用者自訂函數庫與環境變數 (initExtra) ===
    initContent = ''
      # 1. GPG SSH Agent 代理
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)

      # 2. 登出 / 關機
      logout() {
        command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'
      }

      # 3. 代理快速切換（直連 / 全域）
      proxy() {
        if [ $# -eq 0 ]; then
          unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
          echo "🌿 Proxy cleared. Mode: Direct"
        else
          export http_proxy="http://127.0.0.1:$1"
          export https_proxy="http://127.0.0.1:$1"
          export all_proxy="socks5://127.0.0.1:$1"
          export HTTP_PROXY="http://127.0.0.1:$1"
          export HTTPS_PROXY="http://127.0.0.1:$1"
          export ALL_PROXY="socks5://127.0.0.1:$1"
          echo "🌐 Proxy set to port $1. Mode: Global"
        fi
      }

      # 4. 一鍵選區定格截圖
      sss() {
        local filename="$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png"
        mkdir -p "$HOME/Pictures"
        grim -g "$(slurp)" "$filename"
        echo "📸 截圖已儲存至 $filename"
      }

      # 5. OpenCC 繁簡字幕轉換與彩色比對
      cc() {
        local count=0
        if [ $# -eq 0 ]; then
          local target_dirs=("$HOME/下載" "$HOME/Downloads")
          for d in "''${target_dirs[@]}"; do
            if [ -d "$d" ]; then
              echo "🔍 正在掃描目錄: $d ..."
              find "$d" -type f -iname "*.srt" | while IFS= read -r f; do
                [[ "$f" == *.srt.txt ]] && continue
                opencc -i "$f" -o "$f.txt" -c s2twp.json
                echo "✨ 轉繁成功: $f.txt"
                diff --color=always -u "$f" "$f.txt"
                ((count++))
              done
            fi
          done
          [ "$count" -eq 0 ] && echo "📭 沒有找到任何需要轉換的 .srt 檔案。"
        else
          local f="$1"
          if [ -f "$f" ]; then
            opencc -i "$f" -o "$f.txt" -c s2twp.json
            echo "✨ 單檔轉繁成功: $f.txt"
            diff --color=always -u "$f" "$f.txt"
          else
            echo "❌ 找不到檔案: $f"
          fi
        fi
        echo "🎉 所有轉換與對比搞定！"
      }
    '';
  };

  # 3. ⭐️ 智能目錄跳躍 zoxide (z 命令)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # 4. ⭐️ 模糊搜索 FZF
  # programs.fzf = {
  #   enable = true;
  #   enableZshIntegration = true;
  # };

  # 5. ⭐️ 跨終端極速提示符 Starship
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # 6. ⭐️ 使用者級別必備工具鏈
  home.packages = with pkgs; [
    eza         # 現代版 ls
    bat         # 現代版 cat
    fd          # 現代版 find
    ripgrep     # 現代版 grep
    btop        # 現代任務管理器
    opencc      # 字幕繁簡轉換
    diffutils   # 彩色 diff
  ];
}
