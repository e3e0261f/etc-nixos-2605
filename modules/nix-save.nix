{ pkgs, ... }:

{
  environment.systemPackages = [
    # --- 1. nix-test: 測試、熱回滾、離線測試、代理指定與 Waybar 刷新 ---
    (pkgs.writeShellScriptBin "nix-test" ''
      #!/bin/bash
      
      # ⭐️ 支援回滾參數：nix-test --rollback 或 -r
      if [ "$1" = "--rollback" ] || [ "$1" = "-r" ]; then
          echo "⏪ 正在熱回滾測試狀態，恢復至健康世代..."
          if sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test; then
              echo "✅ 已成功還原！所有臨時測試變更已撤銷。"
              systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null
              exit 0
          else
              echo "❌ 熱回滾失敗！建議直接重開機 (sudo reboot)。"
              exit 1
          fi
      fi

      # ⭐️ 解析代理參數 (-p 7890 或 --proxy 7890) 与 离线模式 (-o 或 --offline)
      OFFLINE_FLAGS=""
      CUSTOM_PROXY=""
      
      # 检查命令行参数中的代理设置
      for ((i=1; i<=$#; i++)); do
          arg="''${!i}"
          if [[ "$arg" == "-p" || "$arg" == "--proxy" ]]; then
              next_i=$((i+1))
              port="''${!next_i}"
              if [[ -n "$port" && "$port" =~ ^[0-9]+$ ]]; then
                  CUSTOM_PROXY="http://127.0.0.1:$port"
              fi
          fi
      done

      # 环境变量优先级：命令行 -p > 终端原有 $http_proxy
      PROXY_URL="''${CUSTOM_PROXY:-$http_proxy}"

      if [[ "$*" =~ "--offline" ]] || [[ "$*" =~ "-o" ]]; then
          echo "✈️ 已開啟離線/無網路編譯模式 (禁用 substitute)"
          OFFLINE_FLAGS="--offline --option substitute false"
      else
          if [ -n "$PROXY_URL" ]; then
              echo "🌐 代理模式已生效: $PROXY_URL"
          else
              echo "🌿 直連模式 (如需代理可使用 nix-test -p 7890)"
          fi
      fi
      echo "----------------------------------------"

      # Hyprland 安全檢查 (失敗可強行突破)
      if [ -f ~/.config/hypr/hyprland.lua ] || [ -f ~/.config/hypr/hyprland.conf ]; then
          echo "🔍 正在進行 Hyprland 配置安全檢查..."
          if ! Hyprland --verify-config >/dev/null 2>&1; then
              echo "❌ 警告：Hyprland 配置文件存在語法或加載錯誤！"
              read -p "⚠️ 是否忽略錯誤並強行繼續測試構建？ [y/N] " emergency
              if [[ ! "$emergency" =~ ^[Yy]$ ]]; then
                  echo "💡 提示：你可以選擇強行繼續構建，以使用新的 Nix 配置覆蓋並修復此錯誤。"
                  exit 1
              fi
          else
              echo "✅ Hyprland 配置文件檢查通過。"
          fi
      fi

      echo "🧪 正在執行安全測試 (nixos-rebuild test)..."
      cd /etc/nixos
      git add -A
      git commit -m "update config $(date +%Y-%m-%d)"
      # 带着代理环境变量传递给 sudo
      if sudo http_proxy="$PROXY_URL" https_proxy="$PROXY_URL" nixos-rebuild test --flake .#nixos $OFFLINE_FLAGS; then
          echo "✅ 測試成功！目前效果已臨時生效。"
          systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null
      else
          echo "❌ 測試失敗，請檢查報錯。"
          exit 1
      fi
    '')

    # --- 2. nix-save: 正式構建、二次確認精準回滾、歷史查詢、離線構建、代理指定与 GitHub 同步 ---
    (pkgs.writeShellScriptBin "nix-save" ''
      #!/bin/bash

      # ⭐️ 支援查詢歷史世代清單：nix-save --list 或 -l
      if [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
          echo "📜 當前系統歷史世代清單："
          echo "----------------------------------------"
          sudo nix-env --list-generations -p /nix/var/nix/profiles/system
          exit 0
      fi

      # ⭐️ 支援正式回滾（含二次 Yes 确认）：nix-save --rollback [世代號碼] 或 nix-save -r [世代號碼]
      if [ "$1" = "--rollback" ] || [ "$1" = "-r" ]; then
          TARGET_GEN="$2"
          
          if [[ -n "$TARGET_GEN" && "$TARGET_GEN" =~ ^[0-9]+$ ]]; then
              read -p "⚠️ 確定要將系統回滾至第 $TARGET_GEN 世代嗎？ [y/N] " confirm_rb
              if [[ ! "$confirm_rb" =~ ^[Yy]$ ]]; then
                  echo "📦 已取消回滾操作。"
                  exit 0
              fi

              echo "⏪ 正在精準回滾至第 $TARGET_GEN 世代..."
              if sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation "$TARGET_GEN" && \
                 sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch; then
                  echo "✅ 成功回滾並切換至第 $TARGET_GEN 世代！"
              else
                  echo "❌ 回滾至第 $TARGET_GEN 世代失敗，請使用 'nix-save -l' 檢查該世代是否存在！"
                  exit 1
              fi
          else
              read -p "⚠️ 未指定號碼，確定要回滾至上一個世代 (Generation N-1) 嗎？ [y/N] " confirm_rb
              if [[ ! "$confirm_rb" =~ ^[Yy]$ ]]; then
                  echo "📦 已取消回滾操作。"
                  exit 0
              fi

              echo "⏪ 正在回滾至上一個世代 (Generation N-1)..."
              if sudo nixos-rebuild switch --rollback; then
                  echo "✅ 成功回滾至上一代！"
              else
                  echo "❌ 回滾失敗！"
                  exit 1
              fi
          fi

          systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null
          exit 0
      fi

      # ⭐️ 解析代理參數 (-p 7890 或 --proxy 7890) 与 离线模式 (-o 或 --offline)
      OFFLINE_MODE=false
      OFFLINE_FLAGS=""
      CUSTOM_PROXY=""

      for ((i=1; i<=$#; i++)); do
          arg="''${!i}"
          if [[ "$arg" == "-p" || "$arg" == "--proxy" ]]; then
              next_i=$((i+1))
              port="''${!next_i}"
              if [[ -n "$port" && "$port" =~ ^[0-9]+$ ]]; then
                  CUSTOM_PROXY="http://127.0.0.1:$port"
              fi
          fi
      done

      PROXY_URL="''${CUSTOM_PROXY:-$http_proxy}"

      if [[ "$*" =~ "--offline" ]] || [[ "$*" =~ "-o" ]]; then
          echo "✈️ 已開啟離線/無網路編譯模式 (禁用 substitute)"
          OFFLINE_MODE=true
          OFFLINE_FLAGS="--offline --option substitute false"
      else
          if [ -n "$PROXY_URL" ]; then
              echo "🌐 代理模式已生效: $PROXY_URL"
          else
              echo "🌿 直連模式 (如需代理可使用 nix-save -p 7890)"
          fi
      fi
      echo "----------------------------------------"

      # Hyprland 安全檢查 (失敗可強行突破)
      if [ -f ~/.config/hypr/hyprland.lua ] || [ -f ~/.config/hypr/hyprland.conf ]; then
          echo "🔍 正在進行 Hyprland 配置安全檢查..."
          if ! Hyprland --verify-config >/dev/null 2>&1; then
              echo "❌ 警告：Hyprland 配置文件存在語法錯誤！"
              read -p "⚠️ 是否強行繼續構建以覆蓋修復？ [y/N] " emergency
              [[ ! "$emergency" =~ ^[Yy]$ ]] && exit 1
          else
              echo "✅ Hyprland 配置文件檢查通過。"
          fi
      fi

      cd /etc/nixos
      git add -A
      git commit -m "update config $(date +%Y-%m-%d)"
      echo "正在執行正式構建 (nixos-rebuild switch)..."
      
      # 带着代理环境变量传递给 sudo
      if sudo http_proxy="$PROXY_URL" https_proxy="$PROXY_URL" nixos-rebuild switch --flake .#nixos $OFFLINE_FLAGS; then
        echo "✅ 構建並生成新世代成功！"
        
        systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null

        if [ "$OFFLINE_MODE" = true ]; then
            echo "✈️ 當前為離線模式，已跳過 GitHub 同步。"
            exit 0
        fi

        read -p "🚀 是否同步至 GitHub? [Y/n] " confirm
        confirm=''${confirm:-Y}

        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            current_date=$(date "+%Y-%m-%d %H:%M:%S")
            git commit -m "Save config: $current_date"
            
            echo "正在上傳..."
            if http_proxy="$PROXY_URL" https_proxy="$PROXY_URL" git push; then
                echo "🎉 全部完成！已同步至 GitHub。"
            else
                echo "❌ Git 推送失敗！嘗試手動執行 'git push' 查看原因。"
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
