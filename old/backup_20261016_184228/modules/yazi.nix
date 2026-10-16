# /etc/nixos/modules/yazi.nix
{ pkgs, ... }:

let
  imageViewer = pkgs.imv;
in
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = false; # 避免型別衝突
    shellWrapperName = "y";

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
      };
      opener = {
        edit = [{ run = ''hx "$@"''; block = true; desc = "Helix"; }];
        image = [{ run = ''${imageViewer}/bin/${imageViewer.meta.mainProgram or imageViewer.pname} "$@"''; orphan = true; desc = "View Image"; }];
      };
      open = {
        prepend_rules = [
          { mime = "image/*"; use = "image"; }
          { mime = "text/*"; use = "edit"; }
          { url = "*.nix"; use = "edit"; }
          { url = "*.lua"; use = "edit"; }
          { url = "*.toml"; use = "edit"; }
          { url = "*.rs"; use = "edit"; }
          { url = "*.json"; use = "edit"; }
          { url = "*.md"; use = "edit"; }
          { url = "*.sh"; use = "edit"; }
          { url = "*.fish"; use = "edit"; }
        ];
      };
    };

    # =======================================================
    # ⭐️ 核心：正式在 Yazi 中綁定按鍵
    # =======================================================
    keymap = {
      manager = {
        prepend_keymap = [
          # ⭐️ 當按下 c 再按 a 時，直接呼叫你系統裡的 copyfile 指令！
          {
            on = [ "c" "a" ];
            run = ''shell 'copyfile "$@"' --confirm'';
            desc = "Copy file (via copyfile/cf)";
          }

          # 快速導航保留
          { on = [ "g" "D" ]; run = "cd ~/DOwn"; desc = "Go to ~/DOwn"; }
          { on = [ "g" "n" ]; run = "cd /etc/nixos"; desc = "Go to /etc/nixos"; }
          { on = [ "g" "m" ]; run = "cd /etc/nixos/modules"; desc = "Go to /etc/nixos/modules"; }
          { on = [ "Y" ]; run = ''shell 'copyfile "$@"' --confirm''; desc = "Copy via copyfile"; }
        ];
      };
    };
  };

  # 持久化記憶目錄
  programs.fish.functions.y = ''
    set -l state_dir "$HOME/.local/state/yazi"
    set -l last_file "$state_dir/last-cwd"
    command mkdir -p "$state_dir"

    set -l target_args $argv
    if test (count $argv) -eq 0 -a -f "$last_file"
      set -l saved_cwd (command cat "$last_file" 2>/dev/null)
      if test -n "$saved_cwd" -a -d "$saved_cwd"
        set target_args "$saved_cwd"
      end
    end

    set -l tmp (command mktemp -t "yazi-cwd.XXXXXX")
    command yazi $target_args --cwd-file="$tmp"

    if test -f "$tmp"
      set -l exit_cwd (command cat "$tmp" 2>/dev/null)
      command rm -f "$tmp"
      if test -n "$exit_cwd" -a -d "$exit_cwd"
        echo "$exit_cwd" > "$last_file"
        if test "$exit_cwd" != "$PWD"
          builtin cd -- "$exit_cwd"
        end
      end
    end
  '';

  home.packages = with pkgs; [
    imageViewer
    file
    imagemagick
    ffmpegthumbnailer
    unar
    poppler-utils
    jq
    chafa
  ];

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
}
