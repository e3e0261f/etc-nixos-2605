# /etc/nixos/modules/git.nix
{ pkgs, ... }:

{
  # ⭐️ SSH 模組：遇到 github.com 自動走 443 埠（穿透防火牆）
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
    "github.com" = {
      hostname = "github.com";
      # ... 其他属性保持不变
    };
  };
};

  # ⭐️ Git 模組：配置簽名、預設分支，以及全自動把 HTTPS 轉向 SSH (GPG)
  programs.git = {
    enable = true;

    # 1. 签名配置（保留在顶层，或移动到 settings）
    signing = {
      key = "31C81A9DE1AB870A8EDC3486D7C2DF9FA0283056";
      signByDefault = true;
    };

    # 2. 所有原本的 userName, userEmail 和 extraConfig 统统塞进 settings 里
    settings = {
      user = {
        name = "Rhys";
        email = "e3e0261f@pm.me";
      };

      init.defaultBranch = "main";
      commit.gpgsign = false;

      # ⭐️ 核心宣告式規則：全域將所有 https://github.com/ 自動替換為 SSH 協議（走 GPG 密鑰握手）
      # git clone https://v4.gh-proxy.org/https://github.com/ye3e0261f/etc-nixos-2605.git
      url."https://v4.gh-proxy.org/https://github.com/".insteadOf = "https://github.com/";
    };
  };
}
