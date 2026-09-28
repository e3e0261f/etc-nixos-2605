# /etc/nixos/modules/yazi.nix
{ pkgs, ... }:

let
  # ⭐️ 在此自訂你中意的圖片查看器（切換非常方便）：
  # 推薦 imv（極速、原生支援 Wayland/X11），或換成 pkgs.loupe, pkgs.swayimg, pkgs.feh
  imageViewer = pkgs.imv;
in
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    # =======================================================
    # ⭐️ 1. settings 區塊 (yazi.toml)
    # =======================================================
    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
      };

      opener = {
        # 原有的編輯器設定
        edit = [
          {
            run = ''hx "$@"'';
            block = true;
            desc = "Helix";
          }
        ];

        # 🌟【新增】圖片查看器設定
        image = [
          {
            # 呼叫你指定的查看器，以獨立進程 (orphan = true) 執行，不佔用終端
            run = ''${imageViewer}/bin/${imageViewer.meta.mainProgram or imageViewer.pname} "$@"'';
            orphan = true;
            desc = "View Image";
          }
        ];
      };

      open = {
        prepend_rules = [
          # ⭐️ 只要这一行即可！自动匹配所有类型的图片，调用自订的 image opener
          { mime = "image/*"; use = "image"; }

          # 原有的代碼/文本關聯規則（保持使用 url）
          { mime = "text/*"; use = "edit"; }
          { url = "*.nix"; use = "edit"; }
          { url = "*.lua"; use = "edit"; }
          { url = "*.toml"; use = "edit"; }
          { url = "*.rs"; use = "edit"; }
          { url = "*.json"; use = "edit"; }
          { url = "*.jsonc"; use = "edit"; }
          { url = "*.md"; use = "edit"; }
          { url = "*.sh"; use = "edit"; }
          { url = "*.fish"; use = "edit"; }
          { url = "*.conf"; use = "edit"; }
        ];
      };
    };

    # =======================================================
    # ⭐️ 2. keymap 區塊 (原配置完整保留)
    # =======================================================
    keymap = {
      manager = {
        prepend_keymap = [

          {
            on = [ "c" "a" ];
            # 核心：将选中的文件（%s）转换成 file:// 协议的绝对路径，并通过 wl-copy 塞入系统剪贴板
            run = ''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list'';
            desc = "Copy current/selected files to system clipboard";
          }
          # 按 g 再按大寫 D：秒跳 ~/DOwn/ 目錄
          {
            on = [ "g" "D" ];
            run = "cd ~/DOwn";
            desc = "Go to ~/DOwn";
          }

          # 按 g 再按 n：直達 /etc/nixos
          {
            on = [ "g" "n" ];
            run = "cd /etc/nixos";
            desc = "Go to /etc/nixos";
          }

          # 按 g 再按 m：直達 /etc/nixos/modules
          {
            on = [ "g" "m" ];
            run = "cd /etc/nixos/modules";
            desc = "Go to /etc/nixos/modules";
          }

          # 按 Shift + Y：直接複製檔案實體到剪貼簿 (給 Dolphin/瀏覽器貼上)
          {
            on = [ "Y" ];
            run = ''shell 'copyfile "$@"' --confirm'';
            desc = "Copy file to system clipboard";
          }
        ];
      };
    };
  };

  # =======================================================
  # ⭐️ 3. 多媒體高清預覽與外部工具支援
  # =======================================================
  home.packages = with pkgs; [
    imageViewer        # 確保指定的圖片查看器被安裝
    file               # 核心依賴：Yazi 靠它精準判斷檔案真實 MIME 類型
    imagemagick        # 圖片終端內預覽、裁切、縮放
    ffmpegthumbnailer  # 影片縮圖
    unar               # 壓縮包預覽
    poppler-utils      # PDF 預覽
    jq                 # JSON 格式化高亮
    chafa              # 字符模式圖形降級相容
  ];

  # =======================================================
  # ⭐️ 4. 全域編輯器鎖定為 hx
  # =======================================================
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
}
