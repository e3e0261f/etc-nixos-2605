# /etc/nixos/modules/yazi.nix
{ pkgs, ... }:

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
        edit = [
          {
            run = ''hx "$@"'';
            block = true;
            desc = "Helix";
          }
        ];
      };

      open = {
        prepend_rules = [
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
    # ⭐️ 2. keymap 區塊 (必須在 programs.yazi 裡面！)
    # =======================================================
    keymap = {
      manager = {
        prepend_keymap = [
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
  }; # 👈 programs.yazi 在這裡閉合

  # =======================================================
  # ⭐️ 3. 多媒體高清預覽支援
  # =======================================================
  home.packages = with pkgs; [
    ffmpegthumbnailer
    unar
    poppler-utils
    jq
    chafa
  ];

  # ⭐️ 4. 全域編輯器鎖定為 hx
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
}
