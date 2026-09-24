# /etc/nixos/modules/fcitx.nix
{ pkgs, lib, ... }:

let
  # ⭐️ 1. 直接從你自己的 GitHub 倉庫拉取全部 29 個方案、詞庫與八股文模型！
  rime-clover-src = pkgs.fetchFromGitHub {
    owner = "e3e0261f";
    repo = "NIxos-RIme-GRam";
    rev = "main";
    hash = "sha256-qnRjiSr2ekC6S8V/y/MfNrkohM/4yEMEnS/90P/auk4=";
  };
in
{
  home.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];

  # =======================================================
  # ⭐️ 2. 直接一次性完整部署你的專屬 Rime 倉庫
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

  home.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    # GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx"; # 确保支持 SDL2 的游戏内也能打字
  };

  # 3. 外觀配置：橫排選詞、大字體、Nord-Dark 皮膚
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

  # 5. 行為與熱鍵配置 (Super + Space 切換)
  xdg.configFile."fcitx5/config".text = ''
    [Behavior]
    ShareInputState=No

    [Hotkey]
    EnumerateWithTriggerKeys=True
    EnumerateSkipFirst=False

    [Hotkey/TriggerKeys]
    0=Super+space
  '';

  # 6. Fcitx5 守護服務
  systemd.user.services.fcitx5-daemon = {
    Unit = {
      Description = "Fcitx5 Input Method Daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "/run/current-system/sw/bin/fcitx5";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
