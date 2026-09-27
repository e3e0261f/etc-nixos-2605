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

      services.pipewire.extraConfig.pipewire."99-studio-modules" = {
    "context.modules" = [
      # =======================================================
      # ⭐️ 模組 1：原生人聲 EQ（切低頻 + 提亮高頻）
      # =======================================================
      {
        name = "libpipewire-module-filter-chain";
        flags = [ "ifexists" "nofail" ];
        args = {
          "node.description" = "Studio Vocal EQ";
          "media.name" = "Studio_Vocal_EQ";
          "filter.graph" = {
            nodes = [
              # 高通濾波（80Hz 以下切除，去除噴麥、桌子震動低頻雜音）
              {
                type = "builtin";
                label = "bq_highpass";
                name = "hp_filter";
                control = { "Freq" = 80.0; "Q" = 0.707; };
              }
              # 3000Hz 人聲清晰度微調
              {
                type = "builtin";
                label = "bq_peaking";
                name = "presence";
                control = { "Freq" = 3000.0; "Q" = 1.0; "Gain" = 2.0; };
              }
            ];
            links = [
              { output = "hp_filter:Out"; input = "presence:In"; }
            ];
            inputs = [ "hp_filter:In" ];
            outputs = [ "presence:Out" ];
          };
          "capture.props" = {
            "node.name" = "Studio_EQ_In";
            "media.class" = "Audio/Sink";
          };
          "playback.props" = {
            "node.name" = "Studio_EQ_Out";
            "node.passive" = true;
          };
        };
      }

      # =======================================================
      # ⭐️ 模組 2：經典人聲壓縮器（壓制爆音、使聲音飽滿）
      # =======================================================
      {
        name = "libpipewire-module-filter-chain";
        flags = [ "ifexists" "nofail" ];
        args = {
          "node.description" = "Studio Vocal Compressor";
          "media.name" = "Studio_Vocal_Compressor";
          "filter.graph" = {
            nodes = [
              {
                # 調用經典 SC4 LADSPA 專業硬件級壓縮器
                type = "ladspa";
                plugin = "sc4_1882";
                label = "sc4";
                control = {
                  "RMS/peak" = 0.5;          # 兼顧峰值與平均響度
                  "Attack time (ms)" = 20.0;  # 起控時間
                  "Release time (ms)" = 150.0;# 釋放時間
                  "Threshold level (dB)" = -18.0; # 閾值（超過 -18dB 開始壓縮）
                  "Ratio (1:n)" = 3.5;       # 壓縮比 3.5:1
                  "Knee radius (dB)" = 3.0;   # 軟拐點
                  "Makeup gain (dB)" = 3.0;   # 補償增益
                };
              }
            ];
            inputs = [ "sc4:Left input" "sc4:Right input" ];
            outputs = [ "sc4:Left output" "sc4:Right output" ];
          };
          "capture.props" = {
            "node.name" = "Studio_Compressor_In";
            "media.class" = "Audio/Sink";
          };
          "playback.props" = {
            "node.name" = "Studio_Compressor_Out";
            "node.passive" = true;
          };
        };
      }

      # =======================================================
      # ⭐️ 模組 3：純大廳混響（你的 05Hall5）
      # =======================================================
      {
        name = "libpipewire-module-filter-chain";
        flags = [ "ifexists" "nofail" ];
        args = {
          "node.description" = "Fokke van Saane Hall5";
          "media.name" = "Hall5 Wet Reverb";
          "filter.graph" = {
            nodes = [
              {
                type = "builtin";
                label = "convolver";
                name = "convFL";
                config = { filename = hallIrFile; channel = 0; gain = 1.0; };
              }
              {
                type = "builtin";
                label = "convolver";
                name = "convFR";
                config = { filename = hallIrFile; channel = 1; gain = 1.0; };
              }
            ];
            inputs = [ "convFL:In" "convFR:In" ];
            outputs = [ "convFL:Out" "convFR:Out" ];
          };
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


  # =======================================================
  # 3. 專業音訊工具鏈
  # =======================================================
  environment.systemPackages = with pkgs; [
    pipewire      # pw-top, pw-jack, pw-cli, pw-mon 核心診斷工具
    qpwgraph      # 專業視覺化跳線盤
    pavucontrol   # 音訊控制面板
    ladspaPlugins # 提供 sc4 等工業級壓縮器
    swh_lv2
  ];
}
