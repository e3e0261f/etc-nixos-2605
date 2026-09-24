
{ pkgs, ... }:

{
  # 啟用 GPG Agent 並接管 SSH 認證
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3; # 確保彈出輸入密碼的視窗
  };

  # 確保 SSH 請求會去找 GPG Agent
  environment.shellInit = ''
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';
}
