# /etc/nixos/modules/alarm.nix
{ pkgs, ... }:

let
  # ⭐️ 1. 智慧鬧鐘播放器 (修復自殺 Bug，加強 -w 阻塞等待點擊)
  smart-alarm = pkgs.writeScriptBin "smart-alarm" ''
    #!${pkgs.bash}/bin/bash

    TITLE="''${1:-⏰ 鬧鐘時間到了！}"
    CUSTOM_AUDIO="$2"
    DEFAULT_MUSIC="${./6kg.xm}"

    if [ -n "$CUSTOM_AUDIO" ] && [ -f "$CUSTOM_AUDIO" ]; then
        PLAY_TARGET="$CUSTOM_AUDIO"
    else
        PLAY_TARGET="$DEFAULT_MUSIC"
    fi

    # 1. 在背景啟動音樂播放並取得精確 PID
    ${pkgs.mpv}/bin/mpv --no-video --loop "$PLAY_TARGET" >/dev/null 2>&1 &
    MPV_PID=$!

    # ⭐️ 2. 核心修復：加上 -w (--wait) 參數！
    # 腳本會死死卡在這裡等待！直到你用滑鼠真正點擊了 Mako 通知，它才會放行往下走！
    ${pkgs.libnotify}/bin/notify-send \
        --app-name="SmartAlarm" \
        -u critical \
        -w \
        -i clock \
        "$TITLE" \
        "點擊此處即可關閉鬧鐘。" >/dev/null 2>&1 || true

    # ⭐️ 3. 核心修復：只精確殺死 mpv 播放器，絕對不搞自殺式 pkill！
    kill -9 "$MPV_PID" 2>/dev/null || true

    # 4. 短暫提示已關閉
    ${pkgs.libnotify}/bin/notify-send -t 2000 "已關閉" "鬧鐘已停止播放。"
  '';

  # ⭐️ 2. 升級版排程指令 remind：支援 -f 指定音樂檔案
  remind = pkgs.writeShellScriptBin "remind" ''
    #!/usr/bin/env bash
    set -e

    # 查詢現存排程
    if [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
        echo "📜 當前所有預約的鬧鐘與紀念日清單："
        echo "----------------------------------------------------"
        systemctl --user list-timers "alarm-*"
        exit 0
    fi

    # 取消指定排程
    if [ "$1" = "-c" ] || [ "$1" = "--cancel" ]; then
        TARGET="$2"
        [ -z "$TARGET" ] && { echo "❌ 請輸入要取消的定時器名稱 (可用 remind -l 查詢)"; exit 1; }
        systemctl --user stop "$TARGET" 2>/dev/null || true
        echo "🗑️ 已取消定時器: $TARGET"
        exit 0
    fi

    # 參數解析器
    MODE="once"
    AUDIO_FILE=""
    POSITIONAL=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -y|--yearly)
          MODE="yearly"
          shift
          ;;
        -d|--daily)
          MODE="daily"
          shift
          ;;
        -f|--file)
          AUDIO_FILE="$2"
          shift 2
          ;;
        -h|--help)
          echo "❌ 用法:"
          echo "  remind [選項] <時間規則> <標題> [-f 音訊檔案]"
          echo "範例:"
          echo "  remind -y \"09-10 02:34\" \"查理考克被刺殺紀念日\" -f /home/rhys/Music/1.flac"
          echo "  remind -d \"07:00\" \"早安鬧鐘\" (預設播放內建 Tracker 晶片音樂)"
          exit 0
          ;;
        *)
          POSITIONAL+=("$1")
          shift
          ;;
      esac
    done

    TIME_SPEC="''${POSITIONAL[0]}"
    TITLE="''${POSITIONAL[1]:-紀念日提醒}"

    if [ -z "$TIME_SPEC" ]; then
        echo "❌ 請輸入時間！範例: remind -y \"09-10 02:34\" \"查理考克被刺殺紀念日\" -f /path/to/music.flac"
        exit 1
    fi

    CALENDAR_SPEC=""
    if [ "$MODE" = "yearly" ]; then
        CALENDAR_SPEC="*-$TIME_SPEC:00"
    elif [ "$MODE" = "daily" ]; then
        CALENDAR_SPEC="$TIME_SPEC:00"
    else
        CALENDAR_SPEC="$TIME_SPEC:00"
    fi

    UNIT_NAME="alarm-$(date +%s)"

    # 調用 systemd-run 註冊系統級定時任務
    systemd-run --user \
        --unit="$UNIT_NAME" \
        --description="$TITLE" \
        --on-calendar="$CALENDAR_SPEC" \
        ${smart-alarm}/bin/smart-alarm "$TITLE" "$AUDIO_FILE"

    echo "✅ 成功排程紀念日提醒！"
    echo "  • 標題    : $TITLE"
    echo "  • 時間規則: $CALENDAR_SPEC"
    if [ -n "$AUDIO_FILE" ]; then
      echo "  • 指定音樂: $AUDIO_FILE"
    else
      echo "  • 指定音樂: [內建模組 Chiptune 音樂]"
    fi
    echo "  • 單元名稱: $UNIT_NAME.timer"
  '';
in
{
  home.packages = [
    smart-alarm
    remind
    pkgs.mpv
    pkgs.libnotify
    pkgs.coreutils
  ];

  # ⭐️ 為 Fish 註冊 -f 參數的 Tab 補全 (自動補全音樂檔案路徑)
  xdg.configFile."fish/completions/remind.fish".text = ''
    complete -c remind -s y -l yearly -d "每年重複紀念日 (MM-DD HH:MM)"
    complete -c remind -s d -l daily -d "每天固定鬧鐘 (HH:MM)"
    complete -c remind -s f -l file -r -d "自訂音樂檔案路徑 (FLAC, MP3, WAV, XM, MOD)"
    complete -c remind -s l -l list -d "查看所有已排程清單"
    complete -c remind -s c -l cancel -d "取消指定名稱定時器"
  '';
}
