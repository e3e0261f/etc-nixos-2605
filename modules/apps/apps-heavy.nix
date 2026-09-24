
# /etc/nixos/modules/apps/apps-heavy.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vscodium
    steam
    heroic
    linux-wallpaperengine
    mpvpaper
    aria2
    axel
    bind
    nemo
    thunar
    thunar-volman
    thunar-archive-plugin
    tsx
    libfido2
    fido2-manage
    ruby
    ripgrep
    fd
    dust
    eza
    android-tools 
    peazip  p7zip unzip unrar
    # 你自訂的 FHS 環境
    (let base = pkgs.appimageTools.defaultFhsEnvArgs; in
      pkgs.buildFHSEnv (base // {
        name = "fhs";
        targetPkgs = pkgs: (base.targetPkgs pkgs) ++ (with pkgs; [
          pkg-config
          ncurses
        ]);
        profile = "export FHS=1";
        runScript = "bash";
        extraOutputsToInstall = ["dev"];
      })
    )
  ];

    # 2. bat 配置 (自动配置高亮与主题)
  programs.bat.enable = true;

  # 4. zoxide 配置 (自动注入 Fish 挂载，直接开启 `z` 命令)
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
