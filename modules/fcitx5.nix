{ pkgs, lib, ... }:

let
  rime-frost-src = pkgs.fetchFromGitHub {
    owner = "gaboolic";
    repo = "rime-frost";
    # 鎖定某一穩定點的 rev（此處用 main 的某個實體 hash 或直接用 fetchGit flake 模式）
    rev = "main"; 
    hash = "sha256-A3CY9wwMEKmaaNWFKTEQGT9nS6CUnrnwFaxKaRn4mJs="; 
  };
in
{
  home.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];

  # =======================================================
  # ⭐️ 1. 增量部署保護（修正版：鎖定 rime_frost.schema.yaml）
  # =======================================================
  home.activation.setupRime = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    RIME_DIR="$HOME/.local/share/fcitx5/rime"
    
    # 1. 確保目錄存在
    mkdir -p "$RIME_DIR"
    
    # 2. 將 Flake 抓取的源碼直接鏡像同步過去 (如同 git clone + 清理 .git)
    # -r 递归, -v 显式, --delete 可选(若想完全同步远端)
    cp -rfL ${rime-frost-src}/* "$RIME_DIR/"
    chmod -R u+w "$RIME_DIR"
    
    # 3. 清除不需要的雜物
    rm -rf "$RIME_DIR/.git" "$RIME_DIR/README.md"
  '';

  # =======================================================
  # ⭐️ 2. Rime 配置補丁
  # =======================================================
  xdg.configFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      "ascii_composer/switch_key/Shift_L": commit_code
      "ascii_composer/switch_key/Shift_R": noop
      "switches/@next":
        name: simplification
        reset: 0
  '';

  xdg.configFile."fcitx5/rime/double_pinyin_flypy.custom.yaml".text = ''
    patch:
      "schema/language": zh-hant
      "grammar/language_model": __none__
      "engine/translators/@next": table_translator@english
      english:
        dictionary: english
        spelling_hints: true
        enable_completion: true
        enable_sentence: false
        initial_quality: 0.6
  '';

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

  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Font="Noto Sans CJK TC 18"
    MenuFont="Noto Sans CJK TC 16"
    TrayFont="Noto Sans CJK TC 14"
    Vertical Candidate List=False
    Theme=Nord-Dark
    PerScreenDPI=True
  '';

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

  xdg.configFile."fcitx5/config".text = ''
    [Behavior]
    ShareInputState=No

    [Hotkey]
    EnumerateWithTriggerKeys=True
    EnumerateSkipFirst=False

    [Hotkey/TriggerKeys]
    0=Alt+space
  '';

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
