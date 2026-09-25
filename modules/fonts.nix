# /etc/nixos/modules/fonts.nix
{ pkgs, lib, ... }:

let
  # =========================================================================
  # 🍎 蘋果官方 CDN 原裝字型全自動脫殼 Derivation
  # =========================================================================
  apple-official-fonts = pkgs.stdenvNoCC.mkDerivation {
    pname = "apple-official-fonts";
    version = "2024-latest";

    # 1. 宣告式自動從蘋果官方開發者 CDN 下載正版 DMG 映像檔
    srcs = [
      (pkgs.fetchurl {
        url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
        hash = "sha256-loqzuLH5LC2K9h6waA9cIiTE541ZuYa/AEUCp/wBKRg=";
      })
      (pkgs.fetchurl {
        url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
        hash = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
      })
      (pkgs.fetchurl {
        url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
        hash = "sha256-HC7ttFJswPMm+Lfql49aQzdWR2osjFYHJTdgjtuI+PQ=";
      })
      (pkgs.fetchurl {
        url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
        hash = "sha256-wdDjROut1m62LwP4I3hMzknxeH9WVj+wmPygH8VUE1w=";
      })
    ];

    # 2. 引入 7-Zip 工具作為解壓構建依賴
    nativeBuildInputs = [ pkgs._7zz ];

    # 3. 關閉標準 unpackPhase，手動在構建環境執行三層脫殼流程
    sourceRoot = ".";
    unpackPhase = ''
      runHook preUnpack
      for src in $srcs; do
        7zz x -y "$src" >/dev/null
      done

      # 第二層：解開所有 PKG
      find . -type f -name "*.pkg" -print0 | while IFS= read -r -d "" pkg; do
        7zz x -y -o"$(dirname "$pkg")/extracted" "$pkg" >/dev/null
      done

      # 第三層：解開 Payload 為 Payload~
      find . -type f -name "Payload" -print0 | while IFS= read -r -d "" p; do
        7zz x -y -o"$(dirname "$p")" "$p" >/dev/null
      done

      # 第四層：釋放出最終 .otf 字型
      find . -type f -name "Payload~" -print0 | while IFS= read -r -d "" p; do
        7zz x -y -o"$(dirname "$p")" "$p" >/dev/null
      done
      runHook postUnpack
    '';

    # 4. 安裝到系統字型標準目錄
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/fonts/opentype/apple
      find . -type f \( -name "*.otf" -o -name "*.ttf" \) -exec cp -f {} $out/share/fonts/opentype/apple/ \;
      runHook postInstall
    '';

    meta = with lib; {
      description = "Apple official fonts extracted directly from developer DMGs";
      platforms = platforms.all;
    };
  };
in
{
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;

    # ⭐️ 納入系統字型庫
    packages = with pkgs; [
      apple-official-fonts
      noto-fonts-cjk-sans       # 中文後備支援
      noto-fonts-color-emoji
    ];

    # =======================================================================
    # ⭐️ 核心設定：Fontconfig 優先級覆寫 (解決之前 fc-match 依然是 Noto 的問題)
    # =======================================================================
    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "slight"; # 蘋果官方推薦平滑微調
      };
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      defaultFonts = {
        # 1. 系統 UI / 無襯線字型：SF Pro 絕對最高優先級！
        sansSerif = [
          "SF Pro Display"
          "SF Pro Text"
          "PingFang TC"
          "Noto Sans CJK TC"
        ];

        # 2. 襯線字型：New York
        serif = [
          "New York"
          "Noto Serif CJK TC"
        ];

        # 3. 終端機與代碼：SF Mono
        monospace = [
          "SF Mono"
          "JetBrainsMono Nerd Font"
        ];

        # 4. 表情符號
        emoji = [
          "Apple Color Emoji"
          "Noto Color Emoji"
        ];
      };
    };
  };
}
