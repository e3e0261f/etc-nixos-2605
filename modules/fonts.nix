# /etc/nixos/modules/fonts.nix - 完整文件内容
{ pkgs, lib, ... }:

let
  # =========================================================================
  # 🍎 蘋果官方 CDN 原裝字型全自動脫殼 Derivation
  # =========================================================================
  apple-official-fonts = pkgs.stdenvNoCC.mkDerivation {
    pname = "apple-official-fonts";
    version = "2024-latest";

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

    nativeBuildInputs = [ pkgs._7zz ];

    sourceRoot = ".";
    unpackPhase = ''
      runHook preUnpack
      for src in $srcs; do
        7zz x -y "$src" >/dev/null
      done

      find . -type f -name "*.pkg" -print0 | while IFS= read -r -d "" pkg; do
        7zz x -y -o"$(dirname "$pkg")/extracted" "$pkg" >/dev/null
      done

      find . -type f -name "Payload" -print0 | while IFS= read -r -d "" p; do
        7zz x -y -o"$(dirname "$p")" "$p" >/dev/null
      done

      find . -type f -name "Payload~" -print0 | while IFS= read -r -d "" p; do
        7zz x -y -o"$(dirname "$p")" "$p" >/dev/null
      done
      runHook postUnpack
    '';

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
  fonts.packages = with pkgs; [
    # 1. 苹果风开源门面西文字体（Inter）
    inter
    
    # 2. 核心中文字库（为 Inter 补齐汉字）
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    
    # 3. 终端与代码专用等宽字体（更纱黑体）
    sarasa-gothic
    
    # 4. 老游戏/Steam 必备兼容字体
    wqy_zenhei
  ];

  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      # UI 与常规无衬线字体：
      # 物理逻辑：先吃 Inter（英文变苹果风），Inter 没汉字自动向右借字（Noto Sans CJK TC 繁体）
      sansSerif = [
        "Inter"                 # 英文、数字呈现纯正苹果质感
        "Noto Sans CJK TC"      # 汉字无缝回退，绝不缺字
        "Noto Sans CJK SC"
        "WenQuanYi Zen Hei"
      ];

      # 代码与终端等宽
      monospace = [
        "Sarasa Mono TC"
        "Sarasa Mono SC"
        "DejaVu Sans Mono"
      ];

      serif = [
        "Noto Serif CJK TC"
        "Noto Serif CJK SC"
      ];

      emoji = [ "Noto Color Emoji" ];
    };

    # 【核心防御】：这里选项名为 localConf，底层将直接注入 /etc/fonts/local.conf
    localConf = ''
      <match target="pattern">
        <test name="family"><string>Arial</string></test>
        <edit name="family" mode="append" binding="same">
          <string>WenQuanYi Zen Hei</string>
        </edit>
      </match>
      <match target="pattern">
        <test name="family"><string>Tahoma</string></test>
        <edit name="family" mode="append" binding="same">
          <string>WenQuanYi Zen Hei</string>
        </edit>
      </match>
    '';
  };
}
