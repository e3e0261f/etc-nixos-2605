{ pkgs, ... }:

{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      vim_keys = true;
      update_ms = 300;
    };
  };

  programs.zellij.enable = true;

  home.packages = with pkgs; [
    magic-wormhole-rs
    yazi
    aria2
    axel
    wl-clipboard
  ];
}
