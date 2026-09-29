{ config, pkgs, ... }:

{
  # ============================================================
  # GPG / GPG-Agent
  # ============================================================
  #
  # 目标：
  #   1. 强制使用 pinentry-curses
  #   2. 禁止 GNOME / GTK Pinentry
  #   3. 启用 GPG Agent SSH 支持
  #   4. 给 gpg-agent 一个明确、稳定的 pinentry 路径
  #
  # ============================================================

  programs.gnupg.agent = {
    enable = true;

    # SSH_AUTH_SOCK 使用 gpg-agent 提供 SSH Agent
    enableSSHSupport = true;

    # 唯一允许使用的 Pinentry
    pinentryPackage = pkgs.pinentry-curses;
  };

  # ============================================================
  # 强制 gpg-agent 使用 curses pinentry
  # ============================================================
  #
  # 不依赖 PATH。
  # 不依赖 gpgconf 自动寻找。
  # 不依赖 GNOME Keyring。
  #
  # 直接指定 Nix store 中的真实可执行文件。
  #
  environment.etc."gnupg/gpg-agent.conf".text = ''
    pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses
  '';

  # ============================================================
  # 系统工具
  # ============================================================

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-curses
  ];
}
