{ pkgs, ... }:

{
  # 裝載所有與 OpenCC、MEGA、對比和下載相關的依賴包
  home.packages = with pkgs; [
    megacmd
    opencc
    delta
    aria2
    axel
    diffutils
    libnotify
  ];

  # =======================================================
  # ⭐️ Fish 函式模組庫
  # =======================================================
  programs.fish.functions = {

    # ───────────────────────────────────────────────────
    # 1. scc: 自動在地化字幕轉繁工具 (完全體)
    # ───────────────────────────────────────────────────
    scc = ''
      set -f count 0
      set -f last_file ""
      set -f force_mode 0

      # ⭐️ 1. 檢查是否啟用強制重新翻譯開關 (-f 或 --force)
      if contains -- -f $argv; or contains -- --force $argv
          set force_mode 1
          set -e argv[(contains -i -- -f $argv)] 2>/dev/null
          set -e argv[(contains -i -- --force $argv)] 2>/dev/null
          echo "⚡ 已開啟強制覆蓋模式！"
      end

      # ─────────────────────────────────────────────
      # 模式 A：無參數，自動掃描 ~/下載 與 ~/Downloads
      # ─────────────────────────────────────────────
      if test (count $argv) -eq 0
          set -l target_dirs "$HOME/下載" "$HOME/Downloads"
          for d in $target_dirs
              if test -d "$d"
                  echo "🔍 深度掃描目錄: $d ..."
                  
                  # 使用 -iname 忽略大小寫 (.srt / .SRT)，並排除已生成的 .txt
                  set -l files (find "$d" -type f -iname "*.srt" ! -iname "*.srt.txt" ! -iname "*.txt" 2>/dev/null)
                  
                  for f in $files
                      # 若非強制模式且已轉換過，跳過
                      if test -f "$f.txt"; and test $force_mode -eq 0
                          continue
                      end

                      # 執行 OpenCC 簡轉繁（台灣常用詞彙標準：s2twp）
                      ${pkgs.opencc}/bin/opencc -i "$f" -o "$f.txt" -c s2twp.json
                      echo "✨ 轉繁成功: $f.txt"
                      echo "📊 內容差異對比 (-:簡體 | +:繁體):"
                      ${pkgs.diffutils}/bin/diff --color=always -u "$f" "$f.txt" | head -n 15
                      
                      set count (math $count + 1)
                      set last_file "$f.txt"
                  end
              end
          end
          
          # ⭐️ Mako 全域狀態反饋
          if test $count -eq 0
              echo "📭 無新轉換的檔案（所有字幕皆已是繁體，或可用 scc -f 強制重翻）。"
              ${pkgs.libnotify}/bin/notify-send \
                  -t 3000 \
                  -i dialog-information \
                  "📭 字幕檢查完成" \
                  "所有字幕皆已是繁體，無新檔案。\n如需強制重翻可執行: scc -f"
          else
              echo "📋 正在將最新檔案複製到剪貼簿..."
              copyfile "$last_file"
              ${pkgs.libnotify}/bin/notify-send \
                  -t 3500 \
                  -i edit-copy \
                  "✨ 字幕轉繁完成" \
                  "成功轉換 $count 個字幕！\n最新檔案已放入剪貼簿，直接在 Discord / 檔案管理器 Ctrl+V 貼上！"
          end

      # ─────────────────────────────────────────────
      # 模式 B：手動指定特定檔案
      # ─────────────────────────────────────────────
      else
          for f in $argv
              if test -f "$f"
                  if test -f "$f.txt"; and test $force_mode -eq 0
                      echo "ℹ️ 提示：$f.txt 已存在，直接為您複製至剪貼簿..."
                      copyfile "$f.txt"
                  else
                      ${pkgs.opencc}/bin/opencc -i "$f" -o "$f.txt" -c s2twp.json
                      echo "✨ 轉繁成功: $f.txt"
                      ${pkgs.diffutils}/bin/diff --color=always -u "$f" "$f.txt" | head -n 15
                      copyfile "$f.txt"
                  end
              else
                  echo "❌ 找不到指定檔案: $f"
                  ${pkgs.libnotify}/bin/notify-send \
                      -u critical \
                      -i dialog-error \
                      "❌ 轉繁失敗" \
                      "找不到指定檔案：$f"
              end
          end
      end
    '';

    # ───────────────────────────────────────────────────
    # 2. mega-srt: MEGA 資料夾精準下載字幕並自動轉繁
    # ───────────────────────────────────────────────────
    mega-srt = ''
      if test (count $argv) -eq 0
          echo "⚠️ 用法: mega-srt <MEGA資料夾連結>"
          ${pkgs.libnotify}/bin/notify-send -u critical -i dialog-error "⚠️ MEGA 下載" "請提供有效的 MEGA 資料夾連結！"
          return 1
      end
      set link (string trim -r -c '/' "$argv[1]")
      echo "🔐 正在連接 MEGA 伺服器並解析目錄..."
      ${pkgs.libnotify}/bin/notify-send -t 2500 -i network-transmit-receive "🔐 MEGA" "正在解析加密目錄中的字幕檔..."
      
      set srt_files (mega-ls "$link" 2>/dev/null | grep -i '\.srt$')

      if test (count $srt_files) -eq 0
          echo "📭 該連結中沒有找到任何 .srt 檔案！"
          ${pkgs.libnotify}/bin/notify-send -t 3000 -i dialog-warning "📭 MEGA" "該連結中未找到任何 .srt 字幕！"
          return 1
      end

      echo "🎯 準備下載 "(count $srt_files)" 個字幕檔..."
      for f in $srt_files
          echo "⬇️ 下載中: $f"
          mega-get "$link/$f" ./
      end

      echo "✅ 下載完成！啟動自動轉繁..."
      set -f last_file ""
      for f in $srt_files
          if test -f "$f"
              ${pkgs.opencc}/bin/opencc -i "$f" -o "$f.txt" -c s2twp.json
              echo "✨ [$f] 轉繁完成 -> $f.txt"
              set last_file "$f.txt"
          end
      end

      if test -n "$last_file"
          echo "📋 正在將最新的繁體字幕檔案複製到剪貼簿..."
          copyfile "$last_file"
          ${pkgs.libnotify}/bin/notify-send \
              -t 3500 \
              -i edit-copy \
              "🎉 MEGA 字幕處理完成" \
              "已下載並轉換 "(count $srt_files)" 個字幕！\n最新檔案已就緒，可直接 Ctrl+V 貼上。"
      end
      echo "🎉 全部執行完畢！"
    '';

    # ───────────────────────────────────────────────────
    # 3. 常用多線程高速下載縮寫
    # ───────────────────────────────────────────────────
    adl = "aria2c -s 16 -x 16 -k 1M --continue=true $argv";
    fastget = "axel -n 16 -a $argv";
  };
}
