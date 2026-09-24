# /etc/nixos/ssh-server.nix
{ config, pkgs, ... }:

{
  # 1. SSH 服务端配置（允许别人连进来）
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # 建议后续改为 false 并使用公钥
    };
  };

  # 开放 22 端口供外部连接
  networking.firewall.allowedTCPPorts = [ 22 ];

  # 2. SSH 客户端全局配置（让你访问 GitHub 时自动走 443 端口，彻底解决 22 端口超时/被封锁）
  programs.ssh.extraConfig = ''
    Host github.com
        Hostname ssh.github.com
        Port 443
        User git
  '';
}
