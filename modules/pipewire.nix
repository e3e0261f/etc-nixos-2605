# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

{
  # ⭐️ 1. 錄音棚硬實時權限（保證音訊線程永遠不被系統其他進程打斷）
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "95"; }
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "nice"; type = "-"; value = "-19"; }
  ];

  # 確保當前用戶在 audio 群組
  users.users.rhys.extraGroups = [ "audio" ];

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # ⭐️ 錄音棚靈魂：開啟 JACK 原生相容層
    wireplumber.enable = true;

    # =======================================================
    # 🎙️ PipeWire 主服務：錄音棚基準時鐘架構（256 @ 48kHz）
    # =======================================================
    extraConfig.pipewire."99-pro-studio" = {
      "context.properties" = {
        # 錄音棚標準母帶採樣率：嚴格鎖定 48000Hz，禁止動態變頻
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 48000 ];

        # ⭐️ 錄音棚黃金物理緩衝區：256 幀（5.3ms 超低延遲無感耳返）
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 256;
        # 嚴禁超過 512，徹底杜絕任何流惡意拉大時鐘
        "default.clock.max-quantum" = 512;
        "default.clock.quantum-limit" = 512;

        # 錄音時使用高品質快速線性算法，避免非同步引發的 Jitter
        "resample.quality" = 4;
      };
    };

    # =======================================================
    # 🎧 PulseAudio 相容層（桌面多媒體與錄音分流）
    # =======================================================
    extraConfig.pipewire-pulse."99-studio-pulse" = {
      "pulse.properties" = {
        # 給 Spotify / 瀏覽器充足的內部安全隊列，避免欠載斷流
        "pulse.min.req" = "256/48000";
        "pulse.min.quantum" = "256/48000";
      };
    };

    # =======================================================
    # 🎛️ WirePlumber：聲卡防休眠與 Pro Audio 模式
    # =======================================================
    wireplumber.extraConfig."10-pro-audio" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = "~alsa_.*"; } ];
          actions = {
            update-props = {
              # 徹底禁止聲卡省電休眠（防止錄音起手時爆音或丟失首拍）
              "session.suspend-timeout-seconds" = 0;
              "api.alsa.period-size" = 256;
              "api.alsa.headroom" = 64;
            };
          };
        }
      ];
    };
  };

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
                  name = "convolver";
                  label = "convolver";
                  config = {
                    # 指向你的双声道脉冲 IR 文件
                    filename = "/home/rhys/DOwn/EAsyeffects-main/FokkevanSaane/05Hall5.wav";
                    channel = 0;
                  };
                }
              ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = {
              "node.name" = "effect_input.convolver";
              "media.class" = "Audio/Sink"; # 将自己暴露为一个普通的声卡，设为默认输出即可
            };
            "playback.props" = {
              "node.name" = "effect_output.convolver";
              "node.passive" = true;
            };
          };
        }
      ];
    };

  # ⭐️ 錄音棚必備專業音訊調音台（可視覺化連線，看清每一條音軌）
  environment.systemPackages = with pkgs; [
    qpwgraph      # 視覺化音訊跳線盤（錄音必備神器）
    pavucontrol   # 音量與設備精確控制
  ];
}
