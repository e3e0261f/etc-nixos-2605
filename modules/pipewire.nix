# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:
let
  ladspaDir = "${pkgs.ladspaPlugins}/lib/ladspa";
  # ⚠️ 请确认下面两个文件夹的大小写与你实际路径完全一致
  irDir = "/home/rhys/DOwn/EAsyeffects-main/FokkevanSaane";
  Schellingwoude = "${irDir}/Schellingwoude.wav";
  hallIrFile = "${irDir}/05Hall5.wav";
  sofaFile = "/home/rhys/DOwn/EAsyeffects-main/dtf_nh2.sofa";

  # 统一给所有虚拟音效滤镜降权，防止抢占默认输出，并锁定 48kHz 防止内部重采样死锁
  fxCaptureProps = name: {
    "node.name" = name;
    "media.class" = "Audio/Sink";
    "priority.session" = 100; # 低于物理声卡，绝不抢占默认输出
    "priority.driver" = 100;
    "audio.rate" = 48000;
    "audio.channels" = 2;
    "audio.position" = [
      "FL"
      "FR"
    ];
  };

  fxPlaybackProps =
    name: extra:
    {
      "node.name" = name;
      "node.passive" = true; # 不播放声音时自动休眠，不占 CPU 和缓冲区
      "audio.rate" = 48000;
      "audio.channels" = 2;
      "audio.position" = [
        "FL"
        "FR"
      ];
    }
    // extra;
in
{
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "95";
    }
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "nice";
      type = "-";
      value = "-19";
    }
  ];

  users.users.rhys.extraGroups = [ "audio" ];
  services.pulseaudio.enable = false;

  environment.variables = {
    SPA_SUPPORT_IO_URING = "true";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    extraLadspaPackages = [ pkgs.ladspaPlugins ];

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "core.daemon" = true;
        "cpu.max-align" = 64;
        "support.io-uring" = true;
      };
    };

    # ✅ 1. 解开采样率与缓冲上限死锁（兼容 44.1kHz 蓝牙与 48kHz 专业声卡）
    extraConfig.pipewire."99-pro-studio" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [
          44100
          48000
          96000
        ];
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 8192;
        "resample.quality" = 4;
      };
    };

    extraConfig.pipewire-pulse."99-studio-pulse" = {
      "pulse.properties" = {
        "pulse.min.req" = "512/48000";
        "pulse.default.req" = "1024/48000";
        "pulse.min.quantum" = "512/48000";
      };
    };

    # ✅ 2. 声卡配置 + 蓝牙专属防破音与路由隔离规则
    wireplumber.extraConfig."10-pro-audio-and-bluetooth" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "device.name" = "alsa_card.pci-0000_00_1b.0"; } ];
          actions = {
            update-props = {
              "device.profile" = "pro-audio";
            };
          };
        }
        {
          matches = [
            { "node.name" = "alsa_output.pci-0000_00_1b.0.pro-output-0"; }
            { "node.name" = "alsa_input.pci-0000_00_1b.0.pro-input-0"; }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
              "priority.session" = 2000; # 最高优先级，确保永远是默认物理声卡
              "priority.driver" = 2000;
            };
          };
        }
        {
          matches = [
            { "node.name" = "alsa_output.pci-0000_00_1b.0.pro-output-1"; }
            { "node.name" = "alsa_input.pci-0000_00_1b.0.pro-input-2"; }
          ];
          actions = {
            update-props = {
              "node.disabled" = true;
            };
          };
        }
      ];

      # 🛡️ 蓝牙接收（手机连电脑）防破音、防抢占配置
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        # 只保留高质量立体声（A2DP），防止手机连接时乱切到低音质通话模式导致卡死
        "bluez5.roles" = [
          "a2dp_sink"
          "a2dp_source"
        ];
      };

      "monitor.bluez.rules" = [
        {
          matches = [ { "node.name" = "~bluez_input.*"; } ];
          actions = {
            update-props = {
              # 蓝牙音频直接路由到物理声卡，不经过高负载滤镜链，防止重采样崩溃
              "target.object" = "alsa_output.pci-0000_00_1b.0.pro-output-0";
              "node.latency" = "2048/48000"; # 给蓝牙足够的抗抖动缓冲，彻底消除咔啦破音
            };
          };
        }
      ];
    };

    # =======================================================
    # 🎚️ 錄音棚全家桶效果器機架（已全部注入防抢占与隔离属性）
    # =======================================================
    extraConfig.pipewire."99-studio-modules" = {
      "context.modules" = [
        # 1. 立體聲 EQ
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "FX · EQ · PARAMETRIC";
            "media.name" = "Studio_Vocal_EQ";
            "filter.graph" = {
              nodes = [
                {
                  type = "builtin";
                  label = "bq_highpass";
                  name = "hp_l";
                  control = {
                    "Freq" = 80.0;
                    "Q" = 0.707;
                  };
                }
                {
                  type = "builtin";
                  label = "bq_peaking";
                  name = "presence_l";
                  control = {
                    "Freq" = 3000.0;
                    "Q" = 1.0;
                    "Gain" = 2.5;
                  };
                }
                {
                  type = "builtin";
                  label = "bq_highpass";
                  name = "hp_r";
                  control = {
                    "Freq" = 80.0;
                    "Q" = 0.707;
                  };
                }
                {
                  type = "builtin";
                  label = "bq_peaking";
                  name = "presence_r";
                  control = {
                    "Freq" = 3000.0;
                    "Q" = 1.0;
                    "Gain" = 2.5;
                  };
                }
              ];
              links = [
                {
                  output = "hp_l:Out";
                  input = "presence_l:In";
                }
                {
                  output = "hp_r:Out";
                  input = "presence_r:In";
                }
              ];
              inputs = [
                "hp_l:In"
                "hp_r:In"
              ];
              outputs = [
                "presence_l:Out"
                "presence_r:Out"
              ];
            };
            "capture.props" = fxCaptureProps "Studio_EQ_In";
            "playback.props" = fxPlaybackProps "Studio_EQ_Out" { };
          };
        }

        # 2. SC4 壓縮器
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "FX · COMP · VOCAL";
            "media.name" = "Studio_Vocal_Compressor";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "${ladspaDir}/sc4_1882.so";
                  label = "sc4";
                  name = "sc4";
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
              inputs = [
                "sc4:Left input"
                "sc4:Right input"
              ];
              outputs = [
                "sc4:Left output"
                "sc4:Right output"
              ];
            };
            "capture.props" = fxCaptureProps "Studio_Compressor_In";
            "playback.props" = fxPlaybackProps "Studio_Compressor_Out" { };
          };
        }

        # 3. 噪聲門限器
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "FX · GATE · Noise";
            "media.name" = "Studio_Noise_Gate";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "${ladspaDir}/gate_1410.so";
                  label = "gate";
                  name = "gate_l";
                  control = {
                    "Threshold (dB)" = -40.0;
                    "Attack (ms)" = 2.0;
                    "Hold (ms)" = 50.0;
                    "Decay (ms)" = 100.0;
                    "Range (dB)" = -90.0;
                  };
                }
                {
                  type = "ladspa";
                  plugin = "${ladspaDir}/gate_1410.so";
                  label = "gate";
                  name = "gate_r";
                  control = {
                    "Threshold (dB)" = -40.0;
                    "Attack (ms)" = 2.0;
                    "Hold (ms)" = 50.0;
                    "Decay (ms)" = 100.0;
                    "Range (dB)" = -90.0;
                  };
                }
              ];
              inputs = [
                "gate_l:Input"
                "gate_r:Input"
              ];
              outputs = [
                "gate_l:Output"
                "gate_r:Output"
              ];
            };
            "capture.props" = fxCaptureProps "Studio_Gate_In";
            "playback.props" = fxPlaybackProps "Studio_Gate_Out" { };
          };
        }

        # 4. 電子管溫暖飽和器
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "FX · TUBE · WARMTH";
            "media.name" = "Studio_Tube_Warmth";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "${ladspaDir}/valve_1209.so";
                  label = "valve";
                  name = "valve_l";
                  control = {
                    "Distortion character" = 0.4;
                    "Distortion level" = 0.0;
                  };
                }
                {
                  type = "ladspa";
                  plugin = "${ladspaDir}/valve_1209.so";
                  label = "valve";
                  name = "valve_r";
                  control = {
                    "Distortion character" = 0.4;
                    "Distortion level" = 0.0;
                  };
                }
              ];
              inputs = [
                "valve_l:Input"
                "valve_r:Input"
              ];
              outputs = [
                "valve_l:Output"
                "valve_r:Output"
              ];
            };
            "capture.props" = fxCaptureProps "Studio_Tube_In";
            "playback.props" = fxPlaybackProps "Studio_Tube_Out" { };
          };
        }

        # 5. 磚牆防爆限制器
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "OUT · LIMITER · MASTER";
            "media.name" = "Studio_Brickwall_Limiter";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "${ladspaDir}/fast_lookahead_limiter_1913.so";
                  label = "fastLookaheadLimiter";
                  name = "fastLookaheadLimiter";
                  control = {
                    "Input gain (dB)" = 0.0;
                    "Limit (dB)" = -0.5;
                    "Release time (s)" = 0.05;
                  };
                }
              ];
              inputs = [
                "fastLookaheadLimiter:Input 1"
                "fastLookaheadLimiter:Input 2"
              ];
              outputs = [
                "fastLookaheadLimiter:Output 1"
                "fastLookaheadLimiter:Output 2"
              ];
            };
            "capture.props" = fxCaptureProps "Studio_Limiter_In";
            "playback.props" = fxPlaybackProps "Studio_Limiter_Out" { };
          };
        }
        # 6. SOFA 空間音頻
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "FX · SOFA · MONITORS";
            "media.name" = "Studio_SOFA_Monitors";
            "filter.graph" = {
              nodes = [
                {
                  type = "sofa";
                  label = "spatializer";
                  name = "spFL";
                  config = {
                    filename = sofaFile;
                  };
                  control = {
                    "Azimuth" = 30.0;
                    "Elevation" = 0.0;
                    "Radius" = 1.2;
                  };
                }
                {
                  type = "sofa";
                  label = "spatializer";
                  name = "spFR";
                  config = {
                    filename = sofaFile;
                  };
                  control = {
                    "Azimuth" = 330.0;
                    "Elevation" = 0.0;
                    "Radius" = 1.2;
                  };
                }
                {
                  type = "builtin";
                  label = "mixer";
                  name = "mixL";
                }
                {
                  type = "builtin";
                  label = "mixer";
                  name = "mixR";
                }
              ];
              links = [
                {
                  output = "spFL:Out L";
                  input = "mixL:In 1";
                }
                {
                  output = "spFL:Out R";
                  input = "mixR:In 1";
                }
                {
                  output = "spFR:Out L";
                  input = "mixL:In 2";
                }
                {
                  output = "spFR:Out R";
                  input = "mixR:In 2";
                }
              ];
              inputs = [
                "spFL:In"
                "spFR:In"
              ];
              outputs = [
                "mixL:Out"
                "mixR:Out"
              ];
            };
            "capture.props" = fxCaptureProps "Studio_SOFA_In";
            "playback.props" = fxPlaybackProps "Studio_SOFA_Out" { };
          };
        }
        # 7. 卷積器 2：耳機虛擬音箱空間化
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "OUT · STUDIO · MONITOR";
            "media.name" = "Studio_Monitor_Spatializer";
            "filter.graph" = {
              nodes = [
                {
                  type = "builtin";
                  label = "convolver";
                  name = "spatFL";
                  config = {
                    filename = Schellingwoude;
                    channel = 0;
                    gain = 1.0;
                  };
                }
                {
                  type = "builtin";
                  label = "convolver";
                  name = "spatFR";
                  config = {
                    filename = Schellingwoude;
                    channel = 1;
                    gain = 1.0;
                  };
                }
              ];
              inputs = [
                "spatFL:In"
                "spatFR:In"
              ];
              outputs = [
                "spatFL:Out"
                "spatFR:Out"
              ];
            };
            "capture.props" = fxCaptureProps "Studio_Spatial_In";
            "playback.props" = fxPlaybackProps "Studio_Spatial_Out" {
              "target.object" = "alsa_output.pci-0000_00_1b.0.pro-output-0";
            };
          };
        }
        # 8. 超級音頻放大器（帶防爆保護）
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "SuperAudio · 500% - 1000%";
            "media.name" = "Audio_Booster";
            "filter.graph" = {
              nodes = [
                {
                  type = "builtin";
                  label = "linear";
                  name = "amp_l";
                  control = {
                    "Mult" = 5.0;
                  };
                }
                {
                  type = "builtin";
                  label = "linear";
                  name = "amp_r";
                  control = {
                    "Mult" = 5.0;
                  };
                }
                {
                  type = "ladspa";
                  plugin = "${ladspaDir}/fast_lookahead_limiter_1913.so";
                  label = "fastLookaheadLimiter";
                  name = "limiter";
                  control = {
                    "Input gain (dB)" = 0.0;
                    "Limit (dB)" = -0.5;
                    "Release time (s)" = 0.05;
                  };
                }
              ];
              links = [
                {
                  output = "amp_l:Out";
                  input = "limiter:Input 1";
                }
                {
                  output = "amp_r:Out";
                  input = "limiter:Input 2";
                }
              ];
              inputs = [
                "amp_l:In"
                "amp_r:In"
              ];
              outputs = [
                "limiter:Output 1"
                "limiter:Output 2"
              ];
            };
            "capture.props" = fxCaptureProps "Audio_Booster_In";
            "playback.props" = fxPlaybackProps "Audio_Booster_Out" { };
          };
        }
        # 9. FX · DELAY · STUDIO（修正雙聲道端口映射）
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "FX · DELAY · STUDIO";
            "media.name" = "FX_DELAY_STUDIO";
            "filter.graph" = {
              nodes = [
                {
                  type = "builtin";
                  label = "copy";
                  name = "in_l";
                }
                {
                  type = "builtin";
                  label = "delay";
                  name = "delay_l";
                  config = {
                    "max.delay" = 2.0;
                  };
                  control = {
                    "Delay (s)" = 0.280;
                    "Feedback" = 0.30;
                    "Feedforward" = 0.0;
                  };
                }
                {
                  type = "builtin";
                  label = "mixer";
                  name = "delay_mix_l";
                  control = {
                    "Gain 1" = 0.70;
                    "Gain 2" = 0.30;
                  };
                }
                {
                  type = "builtin";
                  label = "copy";
                  name = "in_r";
                }
                {
                  type = "builtin";
                  label = "delay";
                  name = "delay_r";
                  config = {
                    "max.delay" = 2.0;
                  };
                  control = {
                    "Delay (s)" = 0.420;
                    "Feedback" = 0.30;
                    "Feedforward" = 0.0;
                  };
                }
                {
                  type = "builtin";
                  label = "mixer";
                  name = "delay_mix_r";
                  control = {
                    "Gain 1" = 0.70;
                    "Gain 2" = 0.30;
                  };
                }
              ];
              links = [
                {
                  output = "in_l:Out";
                  input = "delay_l:In";
                }
                {
                  output = "in_l:Out";
                  input = "delay_mix_l:In 1";
                }
                {
                  output = "delay_l:Out";
                  input = "delay_mix_l:In 2";
                }
                {
                  output = "in_r:Out";
                  input = "delay_r:In";
                }
                {
                  output = "in_r:Out";
                  input = "delay_mix_r:In 1";
                }
                {
                  output = "delay_r:Out";
                  input = "delay_mix_r:In 2";
                }
              ];
              inputs = [
                "in_l:In"
                "in_r:In"
              ];
              outputs = [
                "delay_mix_l:Out"
                "delay_mix_r:Out"
              ];
            };
            "capture.props" = fxCaptureProps "FX_DELAY_STUDIO_In";
            "playback.props" = fxPlaybackProps "FX_DELAY_STUDIO_Out" { };
          };
        }
        # 10. FX · FLANGER · STUDIO
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "FX · FLANGER · STUDIO";
            "media.name" = "FX_FLANGER_STUDIO";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "flanger_l";
                  plugin = "${ladspaDir}/flanger_1191.so";
                  label = "flanger";
                  control = {
                    "Delay base (ms)" = 8.0;
                    "Max slowdown (ms)" = 3.0;
                    "LFO frequency (Hz)" = 0.25;
                    "Feedback" = 0.25;
                  };
                }
                {
                  type = "ladspa";
                  name = "flanger_r";
                  plugin = "${ladspaDir}/flanger_1191.so";
                  label = "flanger";
                  control = {
                    "Delay base (ms)" = 8.0;
                    "Max slowdown (ms)" = 3.0;
                    "LFO frequency (Hz)" = 0.25;
                    "Feedback" = 0.25;
                  };
                }
              ];
              inputs = [
                "flanger_l:Input"
                "flanger_r:Input"
              ];
              outputs = [
                "flanger_l:Output"
                "flanger_r:Output"
              ];
            };
            "capture.props" = fxCaptureProps "FX_FLANGER_STUDIO_In";
            "playback.props" = fxPlaybackProps "FX_FLANGER_STUDIO_Out" { };
          };
        }
        # 11. FX · PHASER · STUDIO
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "FX · PHASER · STUDIO";
            "media.name" = "FX_PHASER_STUDIO";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "phaser_l";
                  plugin = "${ladspaDir}/phasers_1217.so";
                  label = "lfoPhaser";
                }
                {
                  type = "ladspa";
                  name = "phaser_r";
                  plugin = "${ladspaDir}/phasers_1217.so";
                  label = "lfoPhaser";
                }
              ];
              inputs = [
                "phaser_l:Input"
                "phaser_r:Input"
              ];
              outputs = [
                "phaser_l:Output"
                "phaser_r:Output"
              ];
            };
            "capture.props" = fxCaptureProps "FX_PHASER_STUDIO_In";
            "playback.props" = fxPlaybackProps "FX_PHASER_STUDIO_Out" { };
          };
        }
        # 12~16. 五組 Overdrive 破音模組
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "🔥 OVERDRIVE · HARD CLIPPER";
            "media.name" = "Studio_Overdrive";
            "filter.graph" = {
              nodes = [
                {
                  type = "builtin";
                  label = "linear";
                  name = "drive_l";
                  control = {
                    "Mult" = 3.0;
                  };
                }
                {
                  type = "builtin";
                  label = "bq_peaking";
                  name = "clip_l";
                  control = {
                    "Freq" = 1500.0;
                    "Q" = 0.5;
                    "Gain" = 12.0;
                  };
                }
                {
                  type = "builtin";
                  label = "linear";
                  name = "drive_r";
                  control = {
                    "Mult" = 3.0;
                  };
                }
                {
                  type = "builtin";
                  label = "bq_peaking";
                  name = "clip_r";
                  control = {
                    "Freq" = 1500.0;
                    "Q" = 0.5;
                    "Gain" = 12.0;
                  };
                }
              ];
              links = [
                {
                  output = "drive_l:Out";
                  input = "clip_l:In";
                }
                {
                  output = "drive_r:Out";
                  input = "clip_r:In";
                }
              ];
              inputs = [
                "drive_l:In"
                "drive_r:In"
              ];
              outputs = [
                "clip_l:Out"
                "clip_r:Out"
              ];
            };
            "capture.props" = fxCaptureProps "Studio_Overdrive_In";
            "playback.props" = fxPlaybackProps "Studio_Overdrive_Out" { };
          };
        }
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "🔥 OVERDRIVE · DIODE";
            "media.name" = "SWH_Diode";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "diode_l";
                  plugin = "${ladspaDir}/diode_1185.so";
                  label = "diode";
                  control = {
                    "Mode (0 for none, 1 for half wave, 2 for full wave)" = 2.0;
                  };
                }
                {
                  type = "ladspa";
                  name = "diode_r";
                  plugin = "${ladspaDir}/diode_1185.so";
                  label = "diode";
                  control = {
                    "Mode (0 for none, 1 for half wave, 2 for full wave)" = 2.0;
                  };
                }
              ];
              inputs = [
                "diode_l:Input"
                "diode_r:Input"
              ];
              outputs = [
                "diode_l:Output"
                "diode_r:Output"
              ];
            };
            "capture.props" = fxCaptureProps "SWH_Diode_In";
            "playback.props" = fxPlaybackProps "SWH_Diode_Out" { };
          };
        }
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "🔥 OVERDRIVE · FAST DRIVE";
            "media.name" = "SWH_FOverdrive";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "foverdrive_l";
                  plugin = "${ladspaDir}/foverdrive_1196.so";
                  label = "foverdrive";
                  control = {
                    "Drive level" = 2.0;
                  };
                }
                {
                  type = "ladspa";
                  name = "foverdrive_r";
                  plugin = "${ladspaDir}/foverdrive_1196.so";
                  label = "foverdrive";
                  control = {
                    "Drive level" = 2.0;
                  };
                }
              ];
              inputs = [
                "foverdrive_l:Input"
                "foverdrive_r:Input"
              ];
              outputs = [
                "foverdrive_l:Output"
                "foverdrive_r:Output"
              ];
            };
            "capture.props" = fxCaptureProps "SWH_FOverdrive_In";
            "playback.props" = fxPlaybackProps "SWH_FOverdrive_Out" { };
          };
        }
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "🔥 OVERDRIVE · TUBE SATURATION";
            "media.name" = "SWH_Valve";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "valve_l";
                  plugin = "${ladspaDir}/valve_1209.so";
                  label = "valve";
                  control = {
                    "Distortion level" = 0.50;
                    "Distortion character" = 0.50;
                  };
                }
                {
                  type = "ladspa";
                  name = "valve_r";
                  plugin = "${ladspaDir}/valve_1209.so";
                  label = "valve";
                  control = {
                    "Distortion level" = 0.50;
                    "Distortion character" = 0.50;
                  };
                }
              ];
              inputs = [
                "valve_l:Input"
                "valve_r:Input"
              ];
              outputs = [
                "valve_l:Output"
                "valve_r:Output"
              ];
            };
            "capture.props" = fxCaptureProps "SWH_Valve_In";
            "playback.props" = fxPlaybackProps "SWH_Valve_Out" { };
          };
        }
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "🔥 OVERDRIVE · TUBE RECTIFIER";
            "media.name" = "SWH_ValveRect";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "valve_rect_l";
                  plugin = "${ladspaDir}/valve_rect_1405.so";
                  label = "valveRect";
                  control = {
                    "Sag level" = 0.50;
                    "Distortion" = 0.50;
                  };
                }
                {
                  type = "ladspa";
                  name = "valve_rect_r";
                  plugin = "${ladspaDir}/valve_rect_1405.so";
                  label = "valveRect";
                  control = {
                    "Sag level" = 0.50;
                    "Distortion" = 0.50;
                  };
                }
              ];
              inputs = [
                "valve_rect_l:Input"
                "valve_rect_r:Input"
              ];
              outputs = [
                "valve_rect_l:Output"
                "valve_rect_r:Output"
              ];
            };
            "capture.props" = fxCaptureProps "SWH_ValveRect_In";
            "playback.props" = fxPlaybackProps "SWH_ValveRect_Out" { };
          };
        }
        # 17. 純大廳混響（05Hall5）
        {
          name = "libpipewire-module-filter-chain";
          flags = [
            "ifexists"
            "nofail"
          ];
          args = {
            "node.description" = "Fokke van Saane Hall5";
            "media.name" = "Hall5 Wet Reverb";
            "filter.graph" = {
              nodes = [
                {
                  type = "builtin";
                  label = "convolver";
                  name = "convFL";
                  config = {
                    filename = hallIrFile;
                    channel = 0;
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
              inputs = [
                "convFL:In"
                "convFR:In"
              ];
              outputs = [
                "convFL:Out"
                "convFR:Out"
              ];
            };
            "capture.props" = fxCaptureProps "Hall5_Soundstage_Sink";
            "playback.props" = fxPlaybackProps "Hall5_Soundstage_Output" {
              "target.object" = "alsa_output.pci-0000_00_1b.0.pro-output-0";
            };
          };
        }
      ];
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/alsa 0755 root root -"
  ];
  systemd.services.init-pro-audio-hardware = {
    description = "Initialize ALC1150 Codec for Pro Audio (Unmute & Line-In)";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for i in $(seq 1 6); do
      if ${pkgs.alsa-utils}/bin/amixer -c PCH info >/dev/null 2>&1; then
      break
      fi
      sleep 0.5
      done
      ${pkgs.alsa-utils}/bin/alsactl restore || true
      ${pkgs.alsa-utils}/bin/amixer -c PCH sset 'Master' 100% unmute || true
      ${pkgs.alsa-utils}/bin/amixer -c PCH sset 'Headphone' 100% unmute || true
      ${pkgs.alsa-utils}/bin/amixer -c PCH sset 'Auto-Mute Mode' 'Disabled' || true
      ${pkgs.alsa-utils}/bin/amixer -c PCH sset 'Input Source' 'Line' || true
      ${pkgs.alsa-utils}/bin/amixer -c PCH sset 'Capture' 20% cap || true
    '';
  };
  environment.systemPackages = with pkgs; [
    pipewire
    qpwgraph
    pavucontrol
    ladspaPlugins
  ];
}
