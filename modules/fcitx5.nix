# /etc/nixos/modules/fcitx.nix
{ pkgs, lib, ... }:

let
  rime-clover-src = pkgs.fetchFromGitHub {
    owner = "e3e0261f";
    repo = "NIxos-RIme-GRam";
    rev = "main";
    hash = "sha256-A3CY9wwMEKmaaNWFKTEQGT9nS6CUnrnwFaxKaRn4mJs=";
  };
in
{
  home.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];

  # =======================================================
  # ⭐️ 1. 一次性完整部署你的專屬 Rime 倉庫
  # =======================================================
  home.activation.setupRime = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    RIME_DIR="$HOME/.local/share/fcitx5/rime"
    if [ ! -f "$RIME_DIR/zh-hans-t-essay-bgw.gram" ]; then
      $DRY_RUN_CMD mkdir -p "$RIME_DIR"
      $DRY_RUN_CMD cp -rfL ${rime-clover-src}/* "$RIME_DIR/"
      $DRY_RUN_CMD chmod -R u+w "$RIME_DIR"
      $DRY_RUN_CMD rm -rf "$RIME_DIR/build" "$RIME_DIR/.git" "$RIME_DIR/README.md"
    fi
  '';

  # =======================================================
  # ⭐️ 2. Rime 全局补丁：锁定英文标点 & 禁用 CapsLock 切换
  # =======================================================
  # 补丁 1: 禁用 Caps_Lock 切换中英文状态 (让 CapsLock 变纯粹)
  xdg.configFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      "ascii_composer/switch_key/Caps_Lock": clear      # 彻底解绑 CapsLock，禁止其切换中英文！
      "ascii_composer/switch_key/Shift_L": commit_code  # 仅保留左 Shift 切换，或者也可以换成 noop 完全不切换
      "ascii_composer/switch_key/Shift_R": noop
  '';

  # 补丁 2: 标点符号映射覆盖，将句号强制固定为半角英文 "."
  xdg.configFile."fcitx5/rime/punctuation.custom.yaml".text = ''
    patch:
      "punctuator/half_shape/.": "."                   # 半角状态下句号输出英文 "."
      "punctuator/full_shape/.": "."                   # 全角状态下句号也强行输出英文 "."
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

  # 5. 行為與熱鍵配置 (Alt + Space 切換)
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
