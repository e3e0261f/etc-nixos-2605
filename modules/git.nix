# /etc/nixos/modules/git.nix
{ pkgs, ... }:

{
  # ⭐️ 1. SSH 模組：將所有 SSH 流量引導至 GitHub 的 443 穿透埠（dae 代理必備）
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        serverAliveInterval = 60;
      };
    };
  };

  # ⭐️ 2. Git 模組：配置讀寫分離加速
  programs.git = {
    enable = true;

    signing = {
      key = "31C81A9DE1AB870A8EDC3486D7C2DF9FA0283056";
      signByDefault = true;
    };

    settings = {
      user = {
        name = "Rhys";
        email = "e3e0261f@pm.me";
      };

      init.defaultBranch = "main";
      commit.gpgsign = true;

      # 🚀【讀加速】：只要你 clone 或 fetch "https://github.com/"，自動換成 gh-proxy 加速節點
      url."https://v4.gh-proxy.org/https://github.com/".insteadOf = "https://github.com/";

      # 🔐【寫安全】：一旦觸發 git push，自動攔截並轉換為 SSH 協議推送
      # 無論本地 Remote 記錄的是原版 URL 還是被替換後的加速站 URL，均轉回 SSH 走 443 埠
      url."git@github.com:" = {
        pushInsteadOf = [
          "https://github.com/"
          "https://v4.gh-proxy.org/https://github.com/"
        ];
      };
    };
  };
}
