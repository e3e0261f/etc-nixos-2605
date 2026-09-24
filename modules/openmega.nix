{ pkgs, ... }:

let
  # ───────────────────────────────────────────────────
  # 1. scc: 自動掃描下載目錄並轉繁字幕 (獨立全域指令)
  # ───────────────────────────────────────────────────
  scc-bin = pkgs.writeScriptBin "scc" ''
    #!${pkgs.fish}/bin/fish

    set -f count 0
    set -f last_file ""
    set -f force_mode 0

    # 檢查是否啟用強制重新翻譯開關 (-f 或 --force)
    if contains -- -f $argv; or contains -- --force $argv
        set force_mode 1
        set -e argv[(contains -i -- -f $argv)] 2>/dev/null
        set -e argv[(contains -i -- --force $argv)] 2>/dev/null
        echo "⚡ 已開啟強制覆蓋模式！"
    end

    # 模式 A：無參數，自動掃描 ~/下載 與 ~/Downloads
    if test (count $argv) -eq 0
        set -l target_dirs "$HOME/下載" "$HOME/Downloads"
        for d in $target_dirs
            if test -d "$d"
                echo "🔍 深度掃描目錄: $d ..."
                set -l files (find "$d" -type f -iname "*.srt" ! -iname "*.srt.txt" ! -iname "*.txt" 2>/dev/null)
                
                for f in $files
                    if test -f "$f.txt"; and test $force_mode -eq 0
                        continue
                    end

                    ${pkgs.opencc}/bin/opencc -i "$f" -o "$f.txt" -c s2twp.json
                    echo "✨ 轉繁成功: $f.txt"
                    ${pkgs.diffutils}/bin/diff --color=always -u "$f" "$f.txt" | head -n 15
                    
                    set count (math $count + 1)
                    set last_file "$f.txt"
                end
            end
        end
        
        # 桌面通知反饋
        if test $count -eq 0
            echo "📭 無新轉換的檔案。"
            ${pkgs.libnotify}/bin/notify-send \
                -t 3000 \
                -i dialog-information \
                "📭 字幕檢查完成" \
                "所有字幕皆已是繁體，無新檔案。\n如需強制重翻可執行: scc -f"
        else
            echo "📋 正在將最新檔案複製到剪貼簿..."
            if type -q copyfile
                copyfile "$last_file"
            else
                ${pkgs.wl-clipboard}/bin/wl-copy < "$last_file"
            end
            ${pkgs.libnotify}/bin/notify-send \
                -t 3500 \
                -i edit-copy \
                "✨ 字幕轉繁完成" \
                "成功轉換 $count 個字幕！\n最新檔案已放入剪貼簿，直接 Ctrl+V 貼上！"
        end

    # 模式 B：手動指定特定檔案
    else
        for f in $argv
            if test -f "$f"
                ${pkgs.opencc}/bin/opencc -i "$f" -o "$f.txt" -c s2twp.json
                echo "✨ 轉繁成功: $f.txt"
                if type -q copyfile
                    copyfile "$f.txt"
                else
                    ${pkgs.wl-clipboard}/bin/wl-copy < "$f.txt"
                end
            else
                echo "❌ 找不到指定檔案: $f"
                ${pkgs.libnotify}/bin/notify-send -u critical -i dialog-error "❌ 轉繁失敗" "找不到指定檔案：$f"
            end
        end
    end
  '';

  # ───────────────────────────────────────────────────
  # 2. mega-srt: MEGA 下載並轉繁 (支援全域無參數自動讀取剪貼簿)
  # ───────────────────────────────────────────────────
  mega-srt-bin = pkgs.writeScriptBin "mega-srt" ''
    #!${pkgs.fish}/bin/fish

    set -l link ""

    # ⭐️ 智慧判斷：如果有給參數就用參數，沒給就自動從剪貼簿抓！
    if test (count $argv) -gt 0
        set link "$argv[1]"
    else
        set link (${pkgs.wl-clipboard}/bin/wl-paste 2>/dev/null)
    end

    set link (string trim -r -c '/' "$link")

    if not string match -q "http*mega.nz*" "$link"
        echo "⚠️ 請提供或複製有效的 MEGA 連結！當前內容: $link"
        ${pkgs.libnotify}/bin/notify-send -u critical -i dialog-error "⚠️ MEGA 下載" "剪貼簿內未偵測到有效的 MEGA 資料夾連結！"
        exit 1
    end

    echo "🔐 正在連接 MEGA 伺服器: $link ..."
    ${pkgs.libnotify}/bin/notify-send -t 2500 -i network-transmit-receive "🔐 MEGA" "正在解析加密目錄中的字幕檔..."
    
    set srt_files (${pkgs.megacmd}/bin/mega-ls "$link" 2>/dev/null | grep -i '\.srt$')

    if test (count $srt_files) -eq 0
        echo "📭 該連結中沒有找到任何 .srt 檔案！"
        ${pkgs.libnotify}/bin/notify-send -t 3000 -i dialog-warning "📭 MEGA" "該連結中未找到任何 .srt 字幕！"
        exit 1
    end

    echo "🎯 準備下載 "(count $srt_files)" 個字幕檔..."
    for f in $srt_files
        echo "⬇️ 下載中: $f"
        ${pkgs.megacmd}/bin/mega-get "$link/$f" $HOME/Downloads/
    end

    echo "✅ 下載完成！啟動自動轉繁..."
    set -f last_file ""
    for f in $srt_files
        set -l target "$HOME/Downloads/$f"
        if test -f "$target"
            ${pkgs.opencc}/bin/opencc -i "$target" -o "$target.txt" -c s2twp.json
            echo "✨ [$f] 轉繁完成 -> $target.txt"
            set last_file "$target.txt"
        end
    end

    if test -n "$last_file"
        if type -q copyfile
            copyfile "$last_file"
        else
            ${pkgs.wl-clipboard}/bin/wl-copy < "$last_file"
        end
        ${pkgs.libnotify}/bin/notify-send \
            -t 3500 \
            -i edit-copy \
            "🎉 MEGA 字幕處理完成" \
            "已下載並轉換 "(count $srt_files)" 個字幕！\n最新檔案已就緒，可直接 Ctrl+V 貼上。"
    end
  '';

in {
  # 裝載所有相依工具 + 我們封裝的全域指令
  home.packages = with pkgs; [
    scc-bin       # ⭐️ 全域可用 scc
    mega-srt-bin  # ⭐️ 全域可用 mega-srt
    megacmd
    opencc
    delta
    aria2
    axel
    diffutils
    libnotify
    wl-clipboard
  ];

  # 常用別名
  programs.fish.shellAliases = {
    adl = "aria2c -s 16 -x 16 -k 1M --continue=true";
    fastget = "axel -n 16 -a";
  };
}
