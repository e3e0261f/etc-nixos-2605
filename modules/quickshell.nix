{ config, pkgs, inputs, ... }:

let
  quickshell = inputs.quickshell.packages.${pkgs.system}.default;
in
{
  home.packages = with pkgs; [
    libcanberra-gtk3
    sound-theme-freedesktop
  ];

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell 1px Ambient HUD";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
