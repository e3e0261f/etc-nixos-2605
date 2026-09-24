{
  inputs = {
    # 将官方 github:NixOS/nixpkgs 替换为清华镜像
    # nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    my-rules.url = "github:e3e0261f/GEoIP-GEoSITE";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    my-rules.flake = false;

    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 1. 引入 Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

      # 添加 quickshell 官方 flake
    quickshell = {
      # 网址与官网最新规范保持一致
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
  
      # ⚠️ 这一行非常重要！
      # 强制让 QuickShell 使用与你系统完全相同的 nixpkgs，防止 Qt 库版本冲突闪退
      inputs.nixpkgs.follows = "nixpkgs";
    };

      # 1. 引入 Caelestia Shell
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs"; # 保证与系统 Qt 库版本一致
    };

    # 如果以後有真正的 cool-config 再打開這裡
    # cool-config.url = "github:super-hacker/cool-hyprland"; 
  };
  # /etc/nixos/flake.nix
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
  nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      { nixpkgs.hostPlatform = "x86_64-linux"; }
      ./configuration.nix
      home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # 💡 這行是關鍵！它能幫你自動移走那些「礙事」的手動檔案
          home-manager.backupFileExtension = "backup"; 
          # 💡 確保這裡是 rhys
          home-manager.users.rhys = import ./modules/home.nix;
          # ⭐️ 必须在同一个大括号内传给 home-manager：
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
