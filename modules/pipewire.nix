# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

let
  # ⭐️ 指向你心愛的大廳脈衝檔案
  hallIrFile = "/home/rhys/DOwn/EAsyeffects-main/FokkevanSaane/05Hall5.wav";
in
{
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "95"; }
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "nice"; type = "-"; value = "-19"; }
  ];

  users.users.rhys.extraGroups = [ "audio" ];
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # 1. 錄音棚基準時鐘（256 @ 48kHz）
    extraConfig.pipewire."99-pro-studio" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 48000 ];
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 512;
        "default.clock.quantum-limit" = 512;
        "resample.quality" = 4;
      };
    };

    extraConfig.pipewire-pulse."99-studio-pulse" = {
      "pulse.properties" = {
        "pulse.min.req" = "256/48000";
        "pulse.min.quantum" = "256/48000";
      };
    };

    # =======================================================
    # ⭐️ 2. Fokke van Saane 05Hall5 原生空間聲場模組
    # =======================================================
    extraConfig.pipewire."99-hall-reverb" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Fokke van Saane Hall5 Soundstage";
            "media.name" = "Fokke van Saane Hall5";
            "filter.graph" = {
              nodes = [
                # 左聲道卷積
                {
                  type = "builtin";
                  name = "conv_fl";
                  label = "convolver";
                  config = {
                    filename = hallIrFile;
                    channel = 0; # 左聲道
                  };
                }
                # 右聲道卷積
                {
                  type = "builtin";
                  name = "conv_fr";
                  label = "convolver";
                  config = {
                    filename = hallIrFile;
                    channel = 1; # 右聲道
                  };
                }
              ];
              links = [
                { output = "conv_fl:Out"; input = "playback:playback_FL"; }
                { output = "conv_fr:Out"; input = "playback:playback_FR"; }
              ];
              inputs = [ "conv_fl:In" "conv_fr:In" ];
              outputs = [ "conv_fl:Out" "conv_fr:Out" ];
            };
            "audio.position" = [ "FL" "FR" ];
            # ⭐️ 註冊為專屬聲場聲卡
            "capture.props" = {
              "node.name" = "Hall5_Soundstage_Sink";
              "media.class" = "Audio/Sink";
            };
            "playback.props" = {
              "node.name" = "Hall5_Soundstage_Output";
              "node.passive" = true;
            };
          };
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    pipewire
    qpwgraph
    pavucontrol
  ];
}
