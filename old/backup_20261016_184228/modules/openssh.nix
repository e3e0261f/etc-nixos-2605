{ config, pkgs, ... }:

let
  # 声明你想要自定义的本地 SSH 服务端端口（例如 22222）
  sshPort = 22222; 
in
{
  # 1. 开启全局 OpenSSH 服务
  services.openssh = {
    enable = true;
    ports = [ sshPort ];

    # 2. 核心安全策略：禁用密码、禁用 Root 直接登录
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };

    # 3. 只保留现代高强度的安全算法主机密钥
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # 4. 系统防火墙自动放行该自定义端口
  networking.firewall.allowedTCPPorts = [ sshPort ];

  # 5. 联动 Fail2ban 自动防御扫描爆破
  services.fail2ban = {
    enable = true;
    maxretry = 5; 
  };
}
