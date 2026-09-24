# /etc/nixos/modules/scripts.nix
{ pkgs, ... }:

let
  # ⭐️ 真正的瞬時定格 + 自動存檔截圖神器
  shot = pkgs.writeShellScriptBin "shot" ''
    #!/usr/bin/env bash
    set -e

    # 1. 確保儲存目錄存在（自動相容 ~/Pictures 與 ~/圖片）
    SAVE_DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$SAVE_DIR"

    TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
    TARGET_FILE="$SAVE_DIR/Screenshot_$TIMESTAMP.png"
    TMP_FULL="/tmp/freeze_frame_$TIMESTAMP.png"

    # 2. ⭐️ 第 0 毫秒：第一時間全螢幕快照
    ${pkgs.grim}/bin/grim "$TMP_FULL"

    MODE="''${1:-area}"

    if [ "$MODE" = "full" ]; then
        cp "$TMP_FULL" "$TARGET_FILE"
        ${pkgs.wl-clipboard}/bin/wl-copy < "$TARGET_FILE"
        ${pkgs.libnotify}/bin/notify-send -i "$TARGET_FILE" "全螢幕截圖已保存" "已存至 ~/Pictures/Screenshots\n已同步複製到剪貼簿"
        rm -f "$TMP_FULL"
        exit 0
    fi

    # 3. ⭐️ 核心黑科技：在拉框時呼叫 hyprpicker 凍結整個 Wayland 畫面，實現真正的「時間停止」！
    # 畫面上所有的動畫、影片、彈出選單在拉框期間將徹底靜止！
    ${pkgs.hyprpicker}/bin/hyprpicker -r -z &
    PICKER_PID=$!

    # 獲取選區座標
    GEOM=$(${pkgs.slurp}/bin/slurp -f "%wx%h+%x+%y" 2>/dev/null) || true

    # 結束畫面凍結
    kill $PICKER_PID 2>/dev/null || true

    # 如果按 Esc 取消，安靜退出
    if [ -z "$GEOM" ]; then
        rm -f "$TMP_FULL"
        exit 0
    fi

    # 4. 精確裁剪並同時寫入「硬碟存檔」與「系統剪貼簿」
    ${pkgs.imagemagick}/bin/magick "$TMP_FULL" -crop "$GEOM" "$TARGET_FILE"
    ${pkgs.wl-clipboard}/bin/wl-copy < "$TARGET_FILE"

    # 發送通知（點擊通知可直接在 Dolphin 裡打開圖片）
    ${pkgs.libnotify}/bin/notify-send -i "$TARGET_FILE" "截圖已保存" "已存至 ~/Pictures/Screenshots/\n已同步複製到剪貼簿！"
    rm -f "$TMP_FULL"
  '';
in
{
  home.packages = [
    pkgs.hyprshot          # ⭐️ 官方推薦截圖神器（完美支援 --freeze）
    pkgs.hyprpicker        # ⭐️ 畫面凍結引擎
    pkgs.grim
    pkgs.slurp
    pkgs.hyprpicker     # ⭐️ 畫面凍結引擎
    pkgs.imagemagick
    pkgs.libnotify
    pkgs.wl-clipboard
    pkgs.wf-recorder

    # 螢幕錄影工具
    (pkgs.writeScriptBin "record-screen" ''
      #!${pkgs.bash}/bin/bash

      RECORD_DIR="$HOME/Videos/Recordings"
      mkdir -p "$RECORD_DIR"

      if pgrep -x "wf-recorder" > /dev/null; then
          pkill -INT -x wf-recorder
          ${pkgs.libnotify}/bin/notify-send "🎬 錄影已完成" "已儲存含聲音的影片至 $RECORD_DIR" -i media-record
          exit 0
      fi

      TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
      FILENAME="$RECORD_DIR/rec_$TIMESTAMP.mp4"
      AUDIO_FLAGS="--audio=alsa_output.pci-0000_00_1b.0.analog-stereo.monitor -C aac"

      if [ "$1" == "area" ]; then
          GEOM=$(${pkgs.slurp}/bin/slurp)
          [ -z "$GEOM" ] && exit 0
          ${pkgs.libnotify}/bin/notify-send "🔴 開始【區域+系統聲音】錄影" "再次按下快捷鍵即可停止" -i media-record
          ${pkgs.wf-recorder}/bin/wf-recorder $AUDIO_FLAGS -g "$GEOM" -f "$FILENAME"
      else
          ${pkgs.libnotify}/bin/notify-send "🔴 開始【全螢幕+系統聲音】錄影" "再次按下快捷鍵即可停止" -i media-record
          ${pkgs.wf-recorder}/bin/wf-recorder $AUDIO_FLAGS -f "$FILENAME"
      fi
    '')

    # 翻譯工具
    (pkgs.writeScriptBin "trans-gui" ''
      #!${pkgs.bash}/bin/bash
      ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" /tmp/sel.png
      ${pkgs.tesseract}/bin/tesseract /tmp/sel.png /tmp/out -l eng 2>/dev/null
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
