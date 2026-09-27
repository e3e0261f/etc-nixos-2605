# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

let
  # ⭐️ 1. 指向你心愛的大廳脈衝響應檔案
  hallIrFile = "/home/rhys/DOwn/EAsyeffects-main/FokkevanSaane/05Hall5.wav";

  # ⭐️ 2. 濕音比例調節（0.15 ~ 0.20 為黃金大廳聲場，0.50 為 50% 濃郁聲場）
  wetLevel = 0.18;
in
{
  # =======================================================
  # 1. 錄音棚內核硬實時權限（Realtime & Memlock）
  # =======================================================
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "95"; }
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "nice";    type = "-"; value = "-19"; }
  ];

  # 確保當前用戶在 audio 群組
  users.users.rhys.extraGroups = [ "audio" ];

  # 徹底停用老舊的 PulseAudio 服務
  services.pulseaudio.enable = false;

  # =======================================================
  # 2. PipeWire 核心服務
  # =======================================================
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # -------------------------------------------------------
    # 🎙️ 主時鐘配置（錄音棚標準 256 @ 48kHz）
    # -------------------------------------------------------
    extraConfig.pipewire."99-pro-studio" = {
      "context.properties" = {
        # 鎖定 48000Hz 基準時鐘，杜絕頻繁變頻引發的抖動
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 48000 ];

        # 物理緩衝區焊死在 256 ~ 512，徹底杜絕應用惡意拉大至 4096
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 512;
        "default.clock.quantum-limit" = 512;

        # 專業標準線性重採樣，兼顧母帶保真度與零 CPU 負擔
        "resample.quality" = 4;
      };
    };

    # -------------------------------------------------------
    # 🎧 PulseAudio 相容層（解決 Spotify 欠載破音）
    # -------------------------------------------------------
    extraConfig.pipewire-pulse."99-studio-pulse" = {
      "pulse.properties" = {
        # 允許客戶端在內部構建安全隊列，不再掐死 max.req
        "pulse.min.req" = "256/48000";
        "pulse.min.quantum" = "256/48000";
      };
    };

    # -------------------------------------------------------
    # 🎛️ WirePlumber：專業音訊鎖定與精準物理通道黑名單
    # -------------------------------------------------------
    wireplumber.extraConfig."10-pro-audio-profile" = {
      "monitor.alsa.rules" = [
        # A. 聲卡設備級別：默認全面應用「專業音訊 (pro-audio)」Profile
        {
          matches = [ { "device.name" = "~alsa_card.*"; } ];
          actions = {
            update-props = {
              "device.profile" = "pro-audio";
            };
          };
        }

        # B. 聲卡節點防休眠與 256 物理週期對齊
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

        # C. ⭐️ 精準黑名單：徹底隱藏所有未接線的幽靈通道！
        {
          matches = [
            # 屏蔽主板未接線的副聲卡 (內部音效 Pro 1)
            { "node.name" = "alsa_output.pci-0000_00_1b.0.pro-output-2"; }

            # 屏蔽顯卡未插線的 5 個 DisplayPort/HDMI 輸出
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-3"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-7"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-8"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-10"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-11"; }
          ];
          actions = {
            update-props = {
              "node.disabled" = true; # 徹底在系統中註銷並隱藏
            };
          };
        }
      ];
    };

    # =======================================================
    # 🏛️ Fokke van Saane 05Hall5 錄音棚純濕聲總線（Pure Wet Reverb）
    # =======================================================
    extraConfig.pipewire."99-hall-reverb" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            # ⭐️ 標記為純濕聲推子
            "node.description" = "Fokke van Saane Hall5 (Wet Reverb Fader)";
            "media.name" = "Hall5 Wet Reverb";
            "filter.graph" = {
              nodes = [
                # 只有卷積器，無任何乾聲干擾！
                {
                  type = "builtin";
                  label = "convolver";
                  name = "convFL";
                  config = {
                    filename = hallIrFile;
                    channel = 0;
                    # 增益設為 1.0，完全交由 pavucontrol 滑塊動態控制濕音大小
                    gain = 1.0;
                  };
                }
                {
                  type = "builtin";
                  label = "convolver";
                  name = "convFR";
                  config = {
                    filename = hallIrFile;
                    channel = 1;
                    gain = 1.0;
                  };
                }
              ];

              # 音訊直接穿過卷積器，輸出 100% 純大廳殘響
              inputs = [ "convFL:In" "convFR:In" ];
              outputs = [ "convFL:Out" "convFR:Out" ];
            };

            "audio.position" = [ "FL" "FR" ];
            "capture.props" = {
              "node.name" = "Hall5_Soundstage_Sink";
              "media.class" = "Audio/Sink";
            };
            "playback.props" = {
              "node.name" = "Hall5_Soundstage_Output";
              "node.passive" = true;
              # ⭐️ 混響計算完畢後，自動發送給你的主板耳機聲卡！
              "target.object" = "alsa_output.pci-0000_00_1b.0.pro-output-0";
            };
          };
        }
      ];
    };
  };

  # =======================================================
  # 3. 專業音訊工具鏈
  # =======================================================
  environment.systemPackages = with pkgs; [
    pipewire      # pw-top, pw-jack, pw-cli, pw-mon 核心診斷工具
    qpwgraph      # 專業視覺化跳線盤
    pavucontrol   # 音訊控制面板
  ];
}
