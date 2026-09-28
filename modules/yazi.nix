# /etc/nixos/modules/yazi.nix
{ pkgs, ... }:

let
  # ⭐️ 在此自訂你中意的圖片查看器（切換非常方便）：
  imageViewer = pkgs.imv;

  # ⭐️ 核心智能剪貼板腳本：滿足「本機檔案系統 + 瀏覽器/Google AI 網頁端」同時完美粘貼
  smartCopyScript = pkgs.writeShellScriptBin "yazi-smart-copy" ''
    if [ $# -eq 0 ]; then
      exit 0
    fi

    FIRST_FILE="$1"

    # 如果有自定義的 copyfile 命令，先執行它
    if command -v copyfile >/dev/null 2>&1; then
      copyfile "$@" 2>/dev/null || true
    fi

    # 針對 Wayland 環境 (wl-copy) 進行深度 MIME 適配：
    if command -v wl-copy >/dev/null 2>&1; then
      MIME_TYPE=$(file --mime-type -b "$FIRST_FILE")

      case "$MIME_TYPE" in
        image/*)
          # ⭐️ 圖片檔案：直接將二進制注入剪貼簿，在 Google AI / 網頁中直接 Ctrl+V 秒出圖片！
          cat "$FIRST_FILE" | wl-copy -t "$MIME_TYPE"
          ;;
        text/*|application/json|application/javascript|application/xml|application/x-sh)
          # ⭐️ 代碼/文本檔案：直接複製文件全文，在 Google AI 聊天框直接 Ctrl+V 貼出內容！
          cat "$FIRST_FILE" | wl-copy
          ;;
        *)
          # 其他檔案：複製為 file:// 協議 URI，支援在檔案管理器之間粘貼
          for path in "$@"; do
            echo "file://$path"
          done | wl-copy -t text/uri-list
          ;;
      esac
    fi
  '';
in
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    # =======================================================
    # ⭐️ 1. settings 區塊 (yazi.toml)
    # =======================================================
    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
      };

      opener = {
        edit = [
          {
            run = ''hx "$@"'';
            block = true;
            desc = "Helix";
          }
        ];

        image = [
          {
            run = ''${imageViewer}/bin/${imageViewer.meta.mainProgram or imageViewer.pname} "$@"'';
            orphan = true;
            desc = "View Image";
          }
        ];
      };

      open = {
        prepend_rules = [
          { mime = "image/*"; use = "image"; }
          { mime = "text/*"; use = "edit"; }
          { url = "*.nix"; use = "edit"; }
          { url = "*.lua"; use = "edit"; }
          { url = "*.toml"; use = "edit"; }
          { url = "*.rs"; use = "edit"; }
          { url = "*.json"; use = "edit"; }
          { url = "*.jsonc"; use = "edit"; }
          { url = "*.md"; use = "edit"; }
          { url = "*.sh"; use = "edit"; }
          { url = "*.fish"; use = "edit"; }
          { url = "*.conf"; use = "edit"; }
        ];
      };
    };

    # =======================================================
    # ⭐️ 2. keymap 區塊
    # =======================================================
    keymap = {
      manager = {
        prepend_keymap = [
          # ⭐️ 滿足需求 B：按 c 再按 a，智能複製！
          # （在 Google AI 貼圖片出圖片、貼 txt 出文字、在檔案管理器貼出檔案）
          {
            on = [ "c" "a" ];
            run = ''shell '${smartCopyScript}/bin/yazi-smart-copy "$@"' --confirm'';
            desc = "Smart copy (pasteable into Google AI / Browser / Dolphin)";
          }

          # 備用：純路徑複製
          {
            on = [ "c" "s" ];
            run = ''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list'';
            desc = "Copy as file:// URI";
          }

          # 快速導航快捷鍵
          {
            on = [ "g" "D" ];
            run = "cd ~/DOwn";
            desc = "Go to ~/DOwn";
          }
          {
            on = [ "g" "n" ];
            run = "cd /etc/nixos";
            desc = "Go to /etc/nixos";
          }
          {
            on = [ "g" "m" ];
            run = "cd /etc/nixos/modules";
            desc = "Go to /etc/nixos/modules";
          }
          {
            on = [ "Y" ];
            run = ''shell '${smartCopyScript}/bin/yazi-smart-copy "$@"' --confirm'';
            desc = "Smart copy file to system clipboard";
          }
        ];
      };
    };
  };

  # =======================================================
  # ⭐️ 滿足需求 A：持久化記憶上次關閉目錄的 Fish 包裝函數
  # =======================================================
  # 覆蓋或增強 y 命令：每次退出保存目錄，每次啟動預設還原上次目錄
  programs.fish.functions.y = {
    description = "Yazi wrapper with persistent last-cwd memory";
    body = ''
      set -l state_dir "$HOME/.local/state/yazi"
      set -l last_file "$state_dir/last-cwd"
      mkdir -p "$state_dir"

      # 如果有給定參數（例如 y /etc/nixos），使用使用者參數；否則嘗試讀取上次儲存的目錄
      set -l target_args $argv
      if test (count $argv) -eq 0 -a -f "$last_file"
        set -l saved_cwd (command cat "$last_file" 2>/dev/null)
        if test -n "$saved_cwd" -a -d "$saved_cwd"
          set target_args "$saved_cwd"
        end
      end

      # 調用 yazi，並要求在退出時寫入目前目錄
      set -l tmp (command mktemp -t "yazi-cwd.XXXXXX")
      command yazi $target_args --cwd-file="$tmp"

      # 讀取退出時的目錄，更新當前 shell 並永久保存
      if test -f "$tmp"
        set -l exit_cwd (command cat "$tmp" 2>/dev/null)
        command rm -f "$tmp"
        if test -n "$exit_cwd" -a -d "$exit_cwd"
          echo "$exit_cwd" > "$last_file"
          builtin cd -- "$exit_cwd"
        end
      end
    '';
  };

  # =======================================================
  # ⭐️ 3. 多媒體與剪貼簿必備工具
  # =======================================================
  home.packages = with pkgs; [
    smartCopyScript    # 確保智能剪貼板腳本可用
    wl-clipboard       # Wayland 剪貼簿核心
    imageViewer        # 圖片查看器
    file               # MIME 識別
    imagemagick        # 圖片預覽
    ffmpegthumbnailer  # 影片縮圖
    unar               # 壓縮包
    poppler-utils      # PDF
    jq                 # JSON
    chafa              # 字符模式圖形
  ];

  # =======================================================
  # ⭐️ 4. 全域編輯器鎖定為 hx
  # =======================================================
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
}
