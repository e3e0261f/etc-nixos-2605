{ pkgs, ... }:

{
  environment.systemPackages = [
    # --- 1. nix-test: 測試、測試回滾並平滑刷新 Waybar ---
    (pkgs.writeShellScriptBin "nix-test" ''
      #!/bin/bash
      
      # ⭐️ 支援回滾參數：nix-test --rollback 或 -r
      if [ "$1" = "--rollback" ] || [ "$1" = "-r" ]; then
          echo "⏪ 正在熱回滾測試狀態，恢復至健康世代..."
          if sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test; then
              echo "✅ 已成功還原！所有臨時測試變更已撤銷。"
              
              # 平滑重啟 Waybar
              systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null
              # echo "🔄 正在平滑重載 Waybar 狀態欄..."
              # pkill -9 waybar 2>/dev/null
              # sleep 0.5
              # systemctl --user restart waybar.service 2>/dev/null || hyprctl dispatch exec waybar
              exit 0
          else
              echo "❌ 熱回滾失敗！建議直接重開機 (sudo reboot)。"
              exit 1
          fi
      fi

      [ -n "$http_proxy" ] && echo "🌐 代理開啟: $http_proxy" || echo "🌿 直連模式"
      echo "----------------------------------------"

      if [ -f ~/.config/hypr/hyprland.lua ]; then
          echo "🔍 正在進行 Lua 語法安全檢查..."
          if ! luajit -bl ~/.config/hypr/hyprland.lua >/dev/null; then
              echo "❌ 警告：~/.config/hypr/hyprland.lua 存在語法錯誤！"
              exit 1
          fi
      fi

      echo "🧪 正在執行安全測試 (nixos-rebuild test)..."
      cd /etc/nixos
      git add -A
      if sudo nixos-rebuild test --flake .#nixos; then
          echo "✅ 測試成功！目前效果已臨時生效。"
          
          # 核心平滑邏輯：重啟單一 Waybar 實例
          systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null
          # echo "🔄 正在平滑重載 Waybar 狀態欄..."
          # pkill -9 waybar 2>/dev/null
          # sleep 0.5
          # systemctl --user restart waybar.service 2>/dev/null || hyprctl dispatch exec waybar
      else
          echo "❌ 測試失敗，請檢查報錯。"
          exit 1
      fi
    '')

    # --- 2. nix-save: 正式構建、精確回滾、歷史查詢與 GitHub 同步 ---
    (pkgs.writeShellScriptBin "nix-save" ''
      #!/bin/bash

      # ⭐️ 支援查詢歷史世代清單：nix-save --list 或 -l
      if [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
          echo "📜 當前系統歷史世代清單："
          echo "----------------------------------------"
          sudo nix-env --list-generations -p /nix/var/nix/profiles/system
          exit 0
      fi

      # ⭐️ 支援正式回滾：nix-save --rollback [世代號碼]
      if [ "$1" = "--rollback" ] || [ "$1" = "-r" ]; then
          TARGET_GEN="$2"
          if [ -n "$TARGET_GEN" ]; then
              echo "⏪ 正在精準回滾至第 $TARGET_GEN 世代..."
              if sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation "$TARGET_GEN" && \
                 sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch; then
                  echo "✅ 成功回滾並切換至第 $TARGET_GEN 世代！"
              else
                  echo "❌ 回滾至第 $TARGET_GEN 世代失敗，請使用 'nix-save -l' 檢查該世代是否存在！"
                  exit 1
              fi
          else
              echo "⏪ 正在回滾至上一個世代 (Generation N-1)..."
              if sudo nixos-rebuild switch --rollback; then
                  echo "✅ 成功回滾至上一代！"
              else
                  echo "❌ 回滾失敗！"
                  exit 1
              fi
          fi

          # 平滑重啟 Waybar
          systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null
          # echo "🔄 正在平滑重載 Waybar 狀態欄..."
          # pkill -9 waybar 2>/dev/null
          # sleep 0.5
          # systemctl --user restart waybar.service 2>/dev/null || hyprctl dispatch exec waybar
          exit 0
      fi

      # 常規存檔與構建邏輯
      [ -n "$http_proxy" ] && echo "🌐 代理開啟: $http_proxy" || echo "🌿 直連模式"
      echo "----------------------------------------"

      if [ -f ~/.config/hypr/hyprland.lua ]; then
          echo "🔍 正在進行 Lua 語法安全檢查..."
          if ! luajit -bl ~/.config/hypr/hyprland.lua >/dev/null; then
              echo "❌ 警告：~/.config/hypr/hyprland.lua 存在語法錯誤！"
              read -p "⚠️ 是否強行繼續？ [y/N] " emergency
              [[ ! "$emergency" =~ ^[Yy]$ ]] && exit 1
          fi
      fi

      cd /etc/nixos
      git add .
      echo "正在執行正式構建 (nixos-rebuild switch)..."
      
      if sudo nixos-rebuild switch --flake .#nixos; then
        echo "✅ 構建並生成新世代成功！"
        
        systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null
        # echo "🔄 正在平滑重載 Waybar 狀態欄..."
        # pkill -9 waybar 2>/dev/null
        # sleep 0.5
        # systemctl --user restart waybar.service 2>/dev/null || hyprctl dispatch exec waybar

        read -p "🚀 是否同步至 GitHub? [Y/n] " confirm
        confirm=''${confirm:-Y}

        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            current_date=$(date "+%Y-%m-%d %H:%M:%S")
            git commit -m "Save config: $current_date"
            
            echo "正在上傳..."
            if git push; then
                echo "🎉 全部完成！已同步至 GitHub。"
            else
                echo "❌ Git 推送失敗！"
                exit 1
            fi
        else
            echo "📦 已取消同步。設定檔僅保存在本地。"
        fi
      else
        echo "❌ 構建失敗，取消後續動作。"
        exit 1
      fi
    '')

    # --- 3. nix-load: 從遠端強制還原 ---
    (pkgs.writeShellScriptBin "nix-load" ''
      set -e
      echo "📥 開始從 GitHub 拉取遠端配置..."
      cd /etc/nixos

      TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
      BACKUP_DIR="/etc/nixos/old/backup_$TIMESTAMP"
      mkdir -p "$BACKUP_DIR"

      echo "📦 正在備份目前配置至 $BACKUP_DIR ..."
      find . -maxdepth 1 ! -name "." ! -name ".git" ! -name "old" ! -name "README.md" -exec mv {} "$BACKUP_DIR/" \;

      echo "🔄 正在與遠端倉庫同步 (git reset --hard)..."
      git fetch origin main
      git reset --hard origin/main

      echo "🚀 同步完成！準備執行系統構建..."
      if sudo nixos-rebuild switch --flake .#nixos; then
          systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null
          # pkill -9 waybar 2>/dev/null
          # systemctl --user restart waybar.service 2>/dev/null || hyprctl dispatch exec waybar
          echo "✨ 系統已成功恢復為遠端最新版本。"
      else
          echo "❌ 構建失敗，備份保存在 $BACKUP_DIR。"
          exit 1
      fi
    '')

    # --- 4. trans-gui: 截圖翻譯 ---
    (pkgs.writeScriptBin "trans-gui" ''
      #!${pkgs.bash}/bin/bash
      grim -g "$(${pkgs.slurp}/bin/slurp)" /tmp/sel.png
      tesseract /tmp/sel.png /tmp/out -l eng 2>/dev/null
      result=$(${pkgs.crow-translate}/bin/crow -e bing -t zh-CN -b -f /tmp/out.txt 2>/dev/null)
      echo "$result" | ${pkgs.wl-clipboard}/bin/wl-copy
      echo "$result" | ${pkgs.yad}/bin/yad --text-info \
        --title="翻譯結果" \
        --width=600 \
        --height=350 \
        --fontname="Noto Sans CJK TC 18" \
        --wrap \
        --button="關閉":0
    '')
  ];
}
