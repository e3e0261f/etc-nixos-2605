# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

{
  # ⭐️ 1. 錄音棚硬實時權限
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "95"; }
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "nice"; type = "-"; value = "-19"; }
  ];

  # 確保你的用戶在 audio 群組
  users.users.rhys.extraGroups = [ "audio" ];

  services.pulseaudio.enable = false;

  # ⭐️ 核心：所有 extraConfig 必須在 services.pipewire 裡面！
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # =======================================================
    # 🎙️ 錄音棚主時鐘架構（256 @ 48kHz）
    # =======================================================
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

    # =======================================================
    # 🎧 PulseAudio 相容層
    # =======================================================
    extraConfig.pipewire-pulse."99-studio-pulse" = {
      "pulse.properties" = {
        "pulse.min.req" = "256/48000";
        "pulse.min.quantum" = "256/48000";
      };
    };

    # =======================================================
    # 🎛️ WirePlumber 防休眠設定
    # =======================================================
    wireplumber.extraConfig."10-pro-audio" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = "~alsa_.*"; } ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
              "api.alsa.period-size" = 256;
              "api.alsa.headroom" = 64;
            };
          };
        }
      ];
    };

    # =======================================================
    # 🌟 PipeWire 原生雙聲道卷積濾鏡（必須放在 services.pipewire 裡面）
    # ⚠️ 提示：請確認 /etc/nixos/audio/my_headphone_eq.wav 檔案真實存在
    # 如果暫時還沒放檔案，請保持下面這段註解，否則啟動時會找不到檔案！
    # =======================================================
    /*
    extraConfig.pipewire."99-convolver-filter" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Studio Calibration Convolver";
            "media.name" = "Studio Calibration Sink";
            "filter.graph" = {
              nodes = [
                {
                  type = "builtin";
                  name = "convolver_FL";
                  label = "convolver";
                  config = {
                    filename = "/etc/nixos/audio/my_headphone_eq.wav";
                    channel = 0;
                  };
                }
                {
                  type = "builtin";
                  name = "convolver_FR";
                  label = "convolver";
                  config = {
                    filename = "/etc/nixos/audio/my_headphone_eq.wav";
                    channel = 1;
                  };
                }
              ];
              links = [
                { output = "convolver_FL:Out"; input = "playback:playback_FL"; }
                { output = "convolver_FR:Out"; input = "playback:playback_FR"; }
              ];
              inputs = [ "convolver_FL:In" "convolver_FR:In" ];
              outputs = [ "convolver_FL:Out" "convolver_FR:Out" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = {
              "node.name" = "effect_input.convolver";
              "media.class" = "Audio/Sink";
            };
            "playback.props" = {
              "node.name" = "effect_output.convolver";
              "node.passive" = true;
            };
          };
        }
      ];
    };
    */
  }; # 👈 services.pipewire 在這裡閉合

  # ⭐️ 專業錄音/音訊除錯工具（不再依賴 EasyEffects）
  environment.systemPackages = with pkgs; [
    qpwgraph      # 專業視覺化音訊跳線盤
    pavucontrol   # 專業音訊模式控制台
  ];
}
