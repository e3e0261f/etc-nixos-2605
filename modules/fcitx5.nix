{ pkgs, lib, ... }:

let
  # 建議鎖定為具體 commit SHA 以確保可重現性。
  # 執行下方指令即可取得最新的 rev 與 hash：
  # nix-shell -p nix-prefetch-github --run "nix-prefetch-github gaboolic rime-frost --rev master"
  rime-frost-src = pkgs.fetchFromGitHub {
    owner = "gaboolic";
    repo = "rime-frost";
    rev = "master"; # 取得 commit SHA 後建議改成具體的 40 位 SHA
    hash = "sha256-52IiUSKvnCEXdIQCSeE8LOhCM3xPDzZZmIL3dEDoNwQ=";
  };
in
{
  home.packages = with pkgs; [
    noto-fonts-cjk-sans # 包含 Noto Sans CJK TC
  ];

  # =======================================================
  # 1. 白霜詞庫安全增量部署（不覆蓋個人詞庫 userdb 與同步資料）
  # =======================================================
  home.activation.setupRime = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    RIME_DIR="$HOME/.local/share/fcitx5/rime"
    MARKER="$RIME_DIR/.rime-frost-src"

    mkdir -p "$RIME_DIR"

    # 僅在 rime-frost-src 版本變動時同步，避免每次 rebuild 都重複編譯詞庫
    if [ ! -f "$MARKER" ] || [ "$(cat "$MARKER")" != "${rime-frost-src}" ]; then
      # --no-preserve=mode 會自動移除 /nix/store 的唯讀權限，無需 chmod -R 污染軟連結
      cp -rfL --no-preserve=mode "${rime-frost-src}/"* "$RIME_DIR/"
      rm -rf "$RIME_DIR/README.md" "$RIME_DIR/build"
      printf '%s' "${rime-frost-src}" > "$MARKER"
    fi
  '';

  # =======================================================
  # 2. Rime 補丁（必須使用 xdg.dataFile -> ~/.local/share/fcitx5/rime）
  # =======================================================
  xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
    force = true;
    onChange = ''
      rm -rf "$HOME/.local/share/fcitx5/rime/build"
    '';
    text = ''
      patch:
        # 預設啟用方案清單（小鹤雙拼排第一為預設，保留白霜全拼備用）
        schema_list:
          - schema: rime_frost_double_pinyin_flypy
          - schema: rime_frost

        # 雙重防護 Caps Lock 死鎖（底層建議再搭配下方 NixOS keyd）
        "ascii_composer/good_old_caps_lock": true
        "ascii_composer/switch_key/Caps_Lock": noop
        "ascii_composer/switch_key/Shift_L": commit_code
        "ascii_composer/switch_key/Shift_R": noop

        # 無論半角或全角，按 . 直接輸出英文句點 .
        "punctuator/half_shape/.": "."
        "punctuator/full_shape/.": "."
    '';
  };

  # 注意：白霜的小鶴雙拼方案 ID 為 rime_frost_double_pinyin_flypy
  # 且白霜已內建 melt_eng 英文混輸，無需額外掛載 english 詞典
  xdg.dataFile."fcitx5/rime/rime_frost_double_pinyin_flypy.custom.yaml" = {
    force = true;
    onChange = ''
      rm -rf "$HOME/.local/share/fcitx5/rime/build"
    '';
    text = ''
      patch:
        # switches/@1 是 traditionalization（[ 简体, 繁体 ]），reset: 1 表示預設繁體
        "switches/@1/reset": 1
        # 採用臺灣正體字形標準（若想連大陸用語一起轉臺灣習慣詞，可改為 s2twp.json）
        "traditionalize/opencc_config": s2tw.json
    '';
  };

  # =======================================================
  # 3. Fcitx5 外觀與輸入法配置（加上 force = true 防止狀態覆寫衝突）
  # =======================================================
  xdg.configFile."fcitx5/conf/classicui.conf" = {
    force = true;
    text = ''
      Font="Noto Sans CJK TC 18"
      MenuFont="Noto Sans CJK TC 16"
      TrayFont="Noto Sans CJK TC 14"
      Vertical Candidate List=False
      Theme=Nord-Dark
      PerScreenDPI=True
    '';
  };

  xdg.configFile."fcitx5/profile" = {
    force = true;
    text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=keyboard-us

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=rime
      Layout=

      [GroupOrder]
      0=Default
    '';
  };

  xdg.configFile."fcitx5/config" = {
    force = true;
    text = ''
      [Behavior]
      ShareInputState=No

      [Hotkey]
      EnumerateWithTriggerKeys=True
      EnumerateSkipFirst=False

      [Hotkey/TriggerKeys]
      0=Alt+space
      # 若下方 keyd 選擇把 Caps Lock 映射為 F13 來切換中英，取消下一行註解即可：
      # 1=F13
    '';
  };

  # 若系統層已啟用 i18n.inputMethod.fcitx5 且使用 waylandFrontend = true，
  # 通常不需要手動設 GTK_IM_MODULE；保留 XMODIFIERS 供 XWayland / 舊應用使用即可
  home.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    QT_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };
}
