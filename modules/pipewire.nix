# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

let
  hallIrFile = "/home/rhys/DOwn/EAsyeffects-main/FokkevanSaane/05Hall5.wav";
in
{
  # =======================================================
  # 1. 內核硬實時權限
  # =======================================================
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "95"; }
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "nice";    type = "-"; value = "-19"; }
  ];

  users.users.rhys.extraGroups = [ "audio" ];
  services.pulseaudio.enable = false;

  # =======================================================
  # 2. PipeWire 核心服務（注意內部不再寫 services.pipewire）
  # =======================================================
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # -------------------------------------------------------
    # 🎙️ 主時鐘（256 @ 48kHz）
    # -------------------------------------------------------
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

    # -------------------------------------------------------
    # 🎛️ WirePlumber：專業音訊與通道黑名單
    # -------------------------------------------------------
    wireplumber.extraConfig."10-pro-audio-profile" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "device.name" = "~alsa_card.*"; } ];
          actions = { update-props = { "device.profile" = "pro-audio"; }; };
        }
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
        # 鎖定真實麥克風為最高優先級
        {
          matches = [ { "node.name" = "alsa_input.pci-0000_00_1b.0.pro-input-0"; } ];
          actions = {
            update-props = {
              "priority.driver" = 2000;
              "priority.session" = 2000;
            };
          };
        }
        # 屏蔽多餘無用通道
        {
          matches = [
            { "node.name" = "alsa_output.pci-0000_00_1b.0.pro-output-1"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-3"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-7"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-8"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-10"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-11"; }
            { "node.name" = "alsa_input.pci-0000_00_1b.0.pro-input-2"; }
          ];
          actions = { update-props = { "node.disabled" = true; }; };
        }
      ];
    };

    # -------------------------------------------------------
    # 🎚️ 3 塊原生錄音棚效果器模組（EQ + 壓縮器 + 大廳混響）
    # -------------------------------------------------------
    extraConfig.pipewire."99-studio-modules" = {
      "context.modules" = [
        # ⭐️ 模組 1：人聲 EQ（切低頻雜音 + 提亮中高頻）
                {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "Studio Vocal EQ (Stereo)";
            "media.name" = "Studio_Vocal_EQ";
            "filter.graph" = {
              nodes = [
                # --- 左聲道濾波鏈 ---
                {
                  type = "builtin";
                  label = "bq_highpass";
                  name = "hp_l";
                  control = { "Freq" = 80.0; "Q" = 0.707; }; # 80Hz 防噴麥切除
                }
                {
                  type = "builtin";
                  label = "bq_peaking";
                  name = "presence_l";
                  control = { "Freq" = 3000.0; "Q" = 1.0; "Gain" = 2.5; }; # 3kHz 人聲清晰度
                }

                # --- 右聲道濾波鏈 ---
                {
                  type = "builtin";
                  label = "bq_highpass";
                  name = "hp_r";
                  control = { "Freq" = 80.0; "Q" = 0.707; };
                }
                {
                  type = "builtin";
                  label = "bq_peaking";
                  name = "presence_r";
                  control = { "Freq" = 3000.0; "Q" = 1.0; "Gain" = 2.5; };
                }
              ];

              # 內部左右聲道各自串聯
              links = [
                { output = "hp_l:Out"; input = "presence_l:In"; }
                { output = "hp_r:Out"; input = "presence_r:In"; }
              ];

              # ⭐️ 核心：導出標準立體聲左右接口！
              inputs = [ "hp_l:In" "hp_r:In" ];
              outputs = [ "presence_l:Out" "presence_r:Out" ];
            };

            # 聲明為立體聲（FL / FR）
            "audio.position" = [ "FL" "FR" ];
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

        # ⭐️ 模組 2：經典 SC4 硬件級人聲壓縮器
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "Studio Vocal Compressor";
            "media.name" = "Studio_Vocal_Compressor";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "sc4_1882";
                  label = "sc4";
                  control = {
                    "RMS/peak" = 0.5;
                    "Attack time (ms)" = 20.0;
                    "Release time (ms)" = 150.0;
                    "Threshold level (dB)" = -18.0;
                    "Ratio (1:n)" = 3.5;
                    "Knee radius (dB)" = 3.0;
                    "Makeup gain (dB)" = 3.0;
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

        # ⭐️ 模組 3：純大廳混響（你的 05Hall5，滑塊獨立調濕音）
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
  }; # 👈 services.pipewire 在這裡閉合

  # =======================================================
  # 3. 系統工具與 LADSPA 效果器演算法庫
  # =======================================================
  environment.systemPackages = with pkgs; [
    pipewire
    qpwgraph
    pavucontrol
    ladspaPlugins # 提供 sc4 硬件壓縮器算法
    swh_lv2
  ];

  # 確保 PipeWire 服務能索引到 LADSPA 效果器路徑
  environment.sessionVariables = {
    LADSPA_PATH = "/run/current-system/sw/lib/ladspa";
  };
}
