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

  # 1. 向 Nix Store 物理拉取字体包，并符号链接到系统级字体目录
  fonts.packages = with pkgs; [
    # 核心西文与符号库
    dejavu_fonts
    
    # 核心中文字库（Google 思源黑体/宋体，解决 99.9% 的汉字与日韩字形缺失）
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    
    # 彩色 Emoji 字体
    noto-fonts-color-emoji
    
    # 程序员最强中英等宽字体（更纱黑体）
    sarasa-gothic
    
    # 经典兜底中文点阵/矢量字库（注意：nixpkgs 中使用下划线命名）
    wqy_zenhei
    wqy_microhei
  ];

  # 2. 生成底层 /etc/fonts/fonts.conf 规则，决定文本渲染时的物理回退流水线
  fonts.fontconfig = {
    enable = true;

    # 遇到字符时，按以下数组顺序从前往后寻找字形（Fallback）
    defaultFonts = {
      monospace = [
        "Sarasa Mono SC"
        "Noto Sans Mono CJK SC"
        "DejaVu Sans Mono"
      ];

      sansSerif = [
        "Noto Sans CJK SC"
        "Noto Sans"
        "DejaVu Sans"
      ];

      serif = [
        "Noto Serif CJK SC"
        "Noto Serif"
        "DejaVu Serif"
      ];

      emoji = [ "Noto Color Emoji" ];
    };
  };
}
