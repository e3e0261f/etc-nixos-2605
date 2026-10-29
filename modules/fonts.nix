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
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;

    # ⭐️ 完整恢复你原本高质量的字型库
    packages = with pkgs; [
      inter                    
      wqy_zenhei 
      sarasa-gothic            # ⭐️ 核心中英文神作：更紗黑體
      noto-fonts-cjk-sans      
      noto-fonts-color-emoji   
      apple-official-fonts
    ];

    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "slight"; 
      };
      subpixel = {
        rgba = "rgb";     
        lcdfilter = "default";
      };

      defaultFonts = {
        sansSerif = [
          "Inter"
          "Sarasa Gothic SC"
          "SF Pro"
          "Noto Sans CJK SC"
        ];
        serif = [
          "New York"
          "Noto Serif CJK TC"
        ];
        monospace = [
          "SF Mono"
          "Sarasa Mono SC"
          "JetBrainsMono Nerd Font"
        ];
        emoji = [
          "Apple Color Emoji"
          "Noto Color Emoji"
        ];
      };

      # 🌐 浏览器与 Steam 专用的字体劫持及中文回退
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <match target="pattern">
            <test name="family" qual="any"><string>-apple-system</string></test>
            <edit name="family" mode="assign" binding="same"><string>Inter</string></edit>
          </match>

          <match target="pattern">
            <test name="family" qual="any"><string>BlinkMacSystemFont</string></test>
            <edit name="family" mode="assign" binding="same"><string>Inter</string></edit>
          </match>

          <match target="pattern">
            <test name="family" qual="any"><string>system-ui</string></test>
            <edit name="family" mode="assign" binding="same"><string>Inter</string></edit>
          </match>

          <match target="pattern">
            <test name="family" qual="any"><string>sans-serif</string></test>
            <edit name="family" mode="append" binding="weak">
              <string>Sarasa Gothic SC</string>
              <string>Noto Sans CJK SC</string>
            </edit>
          </match>

          <match target="pattern">
            <test name="family" qual="any"><string>Inter</string></test>
            <edit name="family" mode="append" binding="weak">
              <string>Sarasa Gothic SC</string>
              <string>Noto Sans CJK SC</string>
            </edit>
          </match>

          <!-- ⭐️ 强制所有未匹配字体默认向更纱黑体回退，彻底根除方块 -->
          <match target="pattern">
            <edit name="family" mode="append" binding="weak">
              <string>Sarasa Gothic SC</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
  };
}
