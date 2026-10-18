{ pkgs, lib, ... }:

let
  rime-clover-src = pkgs.fetchFromGitHub {
    # owner = "e3e0261f";
    # repo = "NIxos-RIme-GRam";
    owner = "gaboolic";
    repo = "rime-frost";
    rev = "main";
    hash = "sha256-A3CY9wwMEKmaaNWFKTEQGT9nS6CUnrnwFaxKaRn4mJs=";
  };
in
{
  home.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];

  # =======================================================
  # ⭐️ 1. 增量部署保護（只要有舊目錄，編譯時絕對不覆蓋，保證記憶不丟）
  # =======================================================
  home.activation.setupRime = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    RIME_DIR="$HOME/.local/share/fcitx5/rime"
    
    # 🛡️ 安全防火牆：只有首次裝系統、文件徹底不存在時才執行複製
    # 只要資料夾在，每次編譯直接跳過（SKIP），絕不沖刷你辛苦攢下的詞頻歷史！
    if [ ! -d "$RIME_DIR" ] || [ ! -f "$RIME_DIR/rime_frost.schema.yaml" ]; then
      $DRY_RUN_CMD mkdir -p "$RIME_DIR"
      $DRY_RUN_CMD cp -rfL ${rime-clover-src}/* "$RIME_DIR/"
      $DRY_RUN_CMD chmod -R u+w "$RIME_DIR"
      $DRY_RUN_CMD rm -rf "$RIME_DIR/build" "$RIME_DIR/.git" "$RIME_DIR/README.md"
    fi
  '';

  # =======================================================
  # ⭐️ 2. Rime 配置補丁（純本地配置，不下載任何外部文件，100%免疫斷網）
  # =======================================================
  xdg.configFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      "ascii_composer/switch_key/Shift_L": commit_code
      "ascii_composer/switch_key/Shift_R": noop
      
      # 🎯 鎖定繁體/正體輸出（不破壞記憶，僅規範後續輸出方向）
      "switches/@next":
        name: simplification
        reset: 0
  '';

  # 🎯 核心核心：通过纯本地配置把小鶴雙拼裡的簡體八股文模型給拔掉！并挂载本地英文
  xdg.configFile."fcitx5/rime/double_pinyin_flypy.custom.yaml".text = ''
    patch:
      "schema/language": zh-hant
      
      # 🛑 徹底切斷跟任何簡體 .gram 模型的關聯！
      # 這行配置會覆蓋掉你 Git 倉庫裡的默認路徑，強行將其重定向為空值。
      # 文件雖然還在硬盤裡，但 Rime 引擎會當它不存在，不再受它干擾！
      "grammar/language_model": __none__
      
      # 🇺🇸 熔接 Rime 內置的本地純英文翻譯器（不再需要從 github 下载任何 easy_en 文件）
      "engine/translators/@next": table_translator@english
      
      # 注入本地純英文習慣配置
      english:
        dictionary: english
        spelling_hints: true
        enable_completion: true   # 開啟英文單詞自動補全
        enable_sentence: false     # 禁用英文自動造句（不允許瞎猜）
        initial_quality: 0.6       # 中英權重完美平衡
  '';

  # 標點符號映射：句號強制固定為半角 "."
  xdg.configFile."fcitx5/rime/punctuation.custom.yaml".text = ''
    patch:
      "punctuator/half_shape/.": "."
      "punctuator/full_shape/.": "."
  '';

  home.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    QT_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  # 3. 外觀配置
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Font="Noto Sans CJK TC 18"
    MenuFont="Noto Sans CJK TC 16"
    TrayFont="Noto Sans CJK TC 14"
    Vertical Candidate List=False
    Theme=Nord-Dark
    PerScreenDPI=True
  '';

  # 4. 輸入法群組配置
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us
    Default IM=keyboard-us

    [Groups/0/Items/0]
    Name=keyboard-us

    [Groups/0/Items/1]
    Name=rime

    [GroupOrder]
    0=Default
  '';

  # 5. 行為與熱鍵配置
  xdg.configFile."fcitx5/config".text = ''
    [Behavior]
    ShareInputState=No

    [Hotkey]
    EnumerateWithTriggerKeys=True
    EnumerateSkipFirst=False

    [Hotkey/TriggerKeys]
    0=Alt+space
  '';

  # 6. Fcitx5 守護服務
  systemd.user.services.fcitx5-daemon = {
    Unit = {
      Description = "Fcitx5 Input Method Daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "/run/current-system/sw/bin/fcitx5";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
