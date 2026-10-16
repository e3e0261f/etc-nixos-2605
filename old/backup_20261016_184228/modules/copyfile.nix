# /etc/nixos/modules/copyfile.nix
{ pkgs, ... }:

let
  copyfile = pkgs.writeShellScriptBin "copyfile" ''
    #!/usr/bin/env bash
    set -e

    CACHE_DIR="/tmp/copyfile-cache"
    mkdir -p "$CACHE_DIR"

    # ⭐️ 失敗時的 Mako 紅色緊急通知
    notify_err() {
        echo "❌ $1" >&2
        ${pkgs.libnotify}/bin/notify-send \
            -u critical \
            -i dialog-error \
            -t 4000 \
            "❌ 剪貼簿複製失敗" "$1"
        exit 1
    }

    # ⭐️ 成功時的 Mako 綠色/常規通知
    notify_ok() {
        echo "📋 $1"
        ${pkgs.libnotify}/bin/notify-send \
            -t 3000 \
            -i edit-copy \
            "📋 剪貼簿已就緒" "$1\n$2"
    }

    # 0. 顯示幫助
    show_help() {
        echo "用法:"
        echo "  copyfile <檔案>             - 原樣複製到剪貼簿"
        echo "  copyfile -t <檔案>          - 自動追加 .txt 後綴複製 (Apple 懶人模式)"
        echo "  copyfile <檔案> .txt        - 自動追加 .txt 後綴"
        echo "  copyfile <檔案> <新檔名>    - 自訂完整新檔名複製"
    }

    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi

    MIME_TYPE="text/uri-list"
    MODE_NAME="可在 Dolphin / Discord / 瀏覽器 直接 Ctrl+V 貼上"

    AUTO_TXT=0
    # 檢查是否啟用 -t 或 --txt 標籤
    if [ "$1" = "-t" ] || [ "$1" = "--txt" ]; then
        AUTO_TXT=1
        shift
    fi

    SRC_FILE="$1"
    [ ! -e "$SRC_FILE" ] && notify_err "找不到來源檔案: $SRC_FILE"

    SRC_ABS="$(${pkgs.coreutils}/bin/realpath "$SRC_FILE" 2>/dev/null)" || notify_err "無法解析檔案路徑: $SRC_FILE"
    SRC_BASE="$(basename "$SRC_FILE")"

    # 1. 處理 -t 模式 (copyfile -t foo.nix -> foo.nix.txt)
    if [ "$AUTO_TXT" -eq 1 ]; then
        TARGET_NAME="''${SRC_BASE}.txt"
        TARGET_PATH="$CACHE_DIR/$TARGET_NAME"
        rm -f "$TARGET_PATH"
        cp -L "$SRC_ABS" "$TARGET_PATH" || notify_err "無法寫入暫存快取"

        echo "file://$TARGET_PATH" | ${pkgs.wl-clipboard}/bin/wl-copy -t text/uri-list
        notify_ok "已自動轉為 TXT：$SRC_BASE ➜ $TARGET_NAME" "$MODE_NAME"
        exit 0
    fi

    # 2. 處理後綴快捷模式 (copyfile foo.nix .txt -> foo.nix.txt)
    if [ $# -eq 2 ] && [[ "$2" =~ ^\.[a-zA-Z0-9]+$ ]]; then
        TARGET_NAME="''${SRC_BASE}$2"
        TARGET_PATH="$CACHE_DIR/$TARGET_NAME"
        rm -f "$TARGET_PATH"
        cp -L "$SRC_ABS" "$TARGET_PATH" || notify_err "無法寫入暫存快取"

        echo "file://$TARGET_PATH" | ${pkgs.wl-clipboard}/bin/wl-copy -t text/uri-list
        notify_ok "已追加後綴：$SRC_BASE ➜ $TARGET_NAME" "$MODE_NAME"
        exit 0
    fi

    # 3. 自訂完整改名模式 (copyfile foo.nix newname.txt)
    if [ $# -eq 2 ] && [ ! -e "$2" ]; then
        TARGET_NAME="$2"
        TARGET_PATH="$CACHE_DIR/$TARGET_NAME"
        rm -f "$TARGET_PATH"
        cp -L "$SRC_ABS" "$TARGET_PATH" || notify_err "無法寫入暫存快取"

        echo "file://$TARGET_PATH" | ${pkgs.wl-clipboard}/bin/wl-copy -t text/uri-list
        notify_ok "已改名複製：$SRC_BASE ➜ $TARGET_NAME" "$MODE_NAME"
        exit 0
    fi

    # 4. 常規多檔案原名複製模式
    for file in "$@"; do
        [ ! -e "$file" ] && notify_err "找不到檔案：$file"
    done

    {
        for file in "$@"; do
            echo "file://$(${pkgs.coreutils}/bin/realpath "$file")"
        done
    } | ${pkgs.wl-clipboard}/bin/wl-copy -t text/uri-list

    if [ $# -eq 1 ]; then
        notify_ok "已複製檔案：$SRC_BASE" "$MODE_NAME"
    else
        notify_ok "已批次複製 $# 個檔案到剪貼簿！" "$MODE_NAME"
    fi
  '';
in
{
   home.packages = [
    copyfile
    pkgs.libnotify
    pkgs.wl-clipboard
  ];

  # ⭐️ 為 Fish 提供絲滑的自動補全
  programs.fish.interactiveShellInit = ''
    complete -c copyfile -s t -l txt -d "自動追加 .txt 並複製 (Apple 懶人模式)"
    complete -c copyfile -s h -l help -d "顯示幫助訊息"
    complete -c copyfile -F
  '';
}
