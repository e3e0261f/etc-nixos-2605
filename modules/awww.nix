# /etc/nixos/modules/awww.nix
{ pkgs, ... }:

let
  # ⭐️ 1. wall-random: 抽圖時徹底清理影片進程與 Socket
  wall-random = pkgs.writeScriptBin "wall-random" ''
    #!${pkgs.bash}/bin/bash
    set -e

    # 清理所有影片進程與通訊管道
    pkill -9 -f "mpvpaper" 2>/dev/null || true
    rm -f /tmp/mpvpaper.sock

    SAVE_DIR="$HOME/Pictures/Wallpapers"
    TMP_IMG="/tmp/wallhaven_downloading.jpg"
    mkdir -p "$SAVE_DIR"

    if ! pgrep -x "awww-daemon" > /dev/null && ! pgrep -x "swww-daemon" > /dev/null; then
        ${pkgs.awww}/bin/awww-daemon &
        sleep 0.3
    fi

    ${pkgs.libnotify}/bin/notify-send \
        -h string:x-canonical-private-synchronous:wall-notify \
        -t 2000 \
        "🎲 正在抽取桌布..." "正在連接 Wallhaven 旗艦圖庫..."

    RAND_SEED=$(head -c 6 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 6)
    RAND_PAGE=$((RANDOM % 10 + 1))
    API_URL="https://wallhaven.cc/api/v1/search?categories=111&purity=111&sorting=random&order=desc&seed=IlaMWn&''${RAND_PAGE}"

    IMG_URL=$(${pkgs.curl}/bin/curl -s "$API_URL" | ${pkgs.jq}/bin/jq -r '.data[0].path' 2>/dev/null || true)

    if [ -z "$IMG_URL" ] || [ "$IMG_URL" = "null" ]; then
        ${pkgs.libnotify}/bin/notify-send \
            -h string:x-canonical-private-synchronous:wall-notify \
            -u critical "❌ 獲取失敗" "無法獲取圖片連結，請檢查網路。"
        exit 1
    fi

    FILENAME=$(basename "$IMG_URL")
    SAVED_PATH="$SAVE_DIR/$FILENAME"

    ${pkgs.curl}/bin/curl -s -L "$IMG_URL" -o "$TMP_IMG"
    cp -f "$TMP_IMG" "$SAVED_PATH"

    ${pkgs.awww}/bin/awww unpause 2>/dev/null || true

    EFFECTS=("grow" "fade" "wipe" "center" "outer")
    RANDOM_EFFECT=''${EFFECTS[$RANDOM % ''${#EFFECTS[@]}]}
    RANDOM_ANGLE=$((RANDOM % 360))

    ${pkgs.awww}/bin/awww img "$SAVED_PATH" \
        --transition-type "$RANDOM_EFFECT" \
        --transition-angle "$RANDOM_ANGLE" \
        --transition-step 90 \
        --transition-fps 60 \
        --transition-duration 1.2 \
        --transition-pos 0.5,0.5

    ${pkgs.libnotify}/bin/notify-send \
        -h string:x-canonical-private-synchronous:wall-notify \
        -i "$SAVED_PATH" \
        -t 3000 \
        "🎉 桌布更換成功！" "特效: $RANDOM_EFFECT (60FPS)\n已存至 ~/Pictures/Wallhaven/"
    
    rm -f "$TMP_IMG"
  '';

  # ⭐️ 2. wall-set: 本地圖片/GIF 載入器
  wall-set = pkgs.writeScriptBin "wall-set" ''
    #!${pkgs.bash}/bin/bash
    TARGET="$1"
    [ -z "$TARGET" ] && { echo "❌ 用法: wall-set /路徑/圖片或動圖.gif"; exit 1; }
    [ ! -f "$TARGET" ] && { echo "❌ 檔案不存在: $TARGET"; exit 1; }

    pkill -9 -f "mpvpaper" 2>/dev/null || true
    rm -f /tmp/mpvpaper.sock
    ${pkgs.awww}/bin/awww unpause 2>/dev/null || true

    EFFECTS=("grow" "fade" "wipe" "center" "outer")
    RANDOM_EFFECT=''${EFFECTS[$RANDOM % ''${#EFFECTS[@]}]}
    RANDOM_ANGLE=$((RANDOM % 360))

    ${pkgs.awww}/bin/awww img "$TARGET" \
        --transition-type "$RANDOM_EFFECT" \
        --transition-angle "$RANDOM_ANGLE" \
        --transition-step 90 \
        --transition-fps 60 \
        --transition-duration 1.2 \
        --transition-pos 0.5,0.5

    ${pkgs.libnotify}/bin/notify-send \
        -h string:x-canonical-private-synchronous:wall-notify \
        -i "$TARGET" \
        -t 2500 \
        "🖼️ 桌布已載入" "特效: $RANDOM_EFFECT (60FPS)"
  '';

  # ⭐️ 3. wall-video: IPC 熱加載 + 滿屏裁切 + 0 閃爍 0 殘留完全體！
  wall-video = pkgs.writeScriptBin "wall-video" ''
    #!${pkgs.bash}/bin/bash
    set -e

    VIDEO_DIR="$HOME/Pictures/Wallhaven"
    HISTORY_FILE="/tmp/wall_video_history.txt"
    SOCKET="/tmp/mpvpaper.sock"
    mkdir -p "$VIDEO_DIR"
    touch "$HISTORY_FILE"

    TARGET="$1"

    # 停止影片桌布並清理 Socket
    if [ "$TARGET" = "--stop" ] || [ "$TARGET" = "-s" ]; then
        pkill -9 -f "mpvpaper" 2>/dev/null || true
        rm -f "$SOCKET"
        ${pkgs.awww}/bin/awww unpause 2>/dev/null || true
        ${pkgs.libnotify}/bin/notify-send \
            -h string:x-canonical-private-synchronous:wall-notify \
            -t 2000 \
            "🎬 動態桌布已停止" "已還原為常規桌布"
        exit 0
    fi

    # 挑選影片（手動指定或洗牌抽取）
    if [ -n "$TARGET" ] && [ -f "$TARGET" ]; then
        SELECTED_VIDEO="$TARGET"
    else
        mapfile -t ALL_VIDEOS < <(find "$VIDEO_DIR" -type f \( -name "*.mp4" -o -name "*.webm" -o -name "*.mkv" \))
        TOTAL_COUNT=''${#ALL_VIDEOS[@]}

        if [ "$TOTAL_COUNT" -eq 0 ]; then
            ${pkgs.libnotify}/bin/notify-send \
                -h string:x-canonical-private-synchronous:wall-notify \
                -u critical "❌ 找不到影片" "目錄 $VIDEO_DIR 中沒有任何影片！"
            exit 1
        fi

        UNPLAYED=()
        for v in "''${ALL_VIDEOS[@]}"; do
            if ! grep -Fxq "$v" "$HISTORY_FILE" 2>/dev/null; then
                UNPLAYED+=("$v")
            fi
        done

        if [ ''${#UNPLAYED[@]} -eq 0 ]; then
            > "$HISTORY_FILE"
            UNPLAYED=("''${ALL_VIDEOS[@]}")
        fi

        RANDOM_INDEX=$((RANDOM % ''${#UNPLAYED[@]}))
        SELECTED_VIDEO="''${UNPLAYED[$RANDOM_INDEX]}"
        echo "$SELECTED_VIDEO" >> "$HISTORY_FILE"
    fi

    # ⭐️ 核心黑科技 1：如果 mpvpaper 已經在運行，直接走 IPC Socket 熱替換！
    # 0 毫秒閃爍、0 幀掉落，視窗不銷毀直接無縫換片！
    if [ -S "$SOCKET" ] && pgrep -f "mpvpaper" >/dev/null; then
        echo "{ \"command\": [\"loadfile\", \"$SELECTED_VIDEO\", \"replace\"] }" | ${pkgs.socat}/bin/socat - "$SOCKET" >/dev/null 2>&1
    else
        # 第一次啟動：徹底清理舊進程與底層殘留
        pkill -9 -f "mpvpaper" 2>/dev/null || true
        rm -f "$SOCKET"
        
        # ⭐️ 核心黑科技 2：將 awww 底層徹底抹黑，絕不漏出舊的靜態圖片！
        ${pkgs.awww}/bin/awww clear "000000" 2>/dev/null || true

        # ⭐️ 核心黑科技 3：
        # - panscan=1.0: 自動滿屏裁切（消除 21:9 寬螢幕上下黑邊）
        # - background-color=#000000: 邊界鎖死純黑
        # - input-ipc-server: 註冊熱切換管道
        MPV_OPTS="--input-ipc-server=$SOCKET --loop-playlist --mute=yes --volume=0 --hwdec=vaapi --video-sync=display-resample --interpolation=no --opengl-pbo=yes --panscan=1.0 --background-color=#000000 --vd-lavc-threads=4"
        ${pkgs.mpvpaper}/bin/mpvpaper -o "$MPV_OPTS" '*' "$SELECTED_VIDEO" &
    fi

    FILENAME=$(basename "$SELECTED_VIDEO")
    REMAINING=$((''${#UNPLAYED[@]} - 1))
    ${pkgs.libnotify}/bin/notify-send \
        -h string:x-canonical-private-synchronous:wall-notify \
        -t 3000 \
        "🎬 4K 動態桌布已就緒" "🎲 播放: $FILENAME\n⚡ IPC 零閃爍熱切換 | 滿屏無黑邊"
  '';
in
{
  home.packages = with pkgs; [
    awww
    mpvpaper
    wall-random
    wall-set
    wall-video
    socat          # ⭐️ IPC 通訊必備
    jq
    curl
    libnotify
  ];
}
