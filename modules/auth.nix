{ config, pkgs, ... }:

{
  programs.gnupg.agent = {
    enable = true;

    # 使用 GPG Agent 提供 SSH Agent
    enableSSHSupport = true;

    # 终端直接输入 GPG 密码
    pinentryPackage = pkgs.pinentry-tty;
  };

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-tty
  ];
}
