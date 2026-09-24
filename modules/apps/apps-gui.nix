
# /etc/nixos/modules/apps/apps-gui.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome       # 或 chromium
    spotify
    discord
    keepassxc
    crow-translate
    gimagereader
    tesseract
    waypaper
    loupe
    spotify
    ente-auth
    hydrogen  #强大鼓机
    sonic-pi
    supercollider
    # emacs-pgtk
    sl
  ];
}
