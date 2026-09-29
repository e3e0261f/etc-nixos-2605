# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:
let
  # 📁 指向你的寶庫基礎路徑：
  irDir = "/home/rhys/DOwn/EAsyeffects-main/FokkevanSaane";
  # hallIrFile = "/home/rhys/DOwn/EAsyeffects-main/6Spaces13Hillside48K.wav";

  # ⭐️【大場地菜單】：把你想聽的那個取消註釋，其他加上 # 即可！
  
  # 🏛️ 1. 歐洲宏偉古大教堂（最空靈、聲場最大）：
  Schellingwoude = "${irDir}/Schellingwoude.wav";

  # 🏛️ 2. 大教堂後排聽音位（超強縱深包圍感）：
  # buikslootRear = "${irDir}/Buiksloot Rear.wav";

  # 🏭 3. 巨型挑高展廳（橫向聲場極度開闊，現代感）：
  # Transformatorhuis = "${irDir}/Transformatorhuis wide.wav";

  # 🏭 4. 巨型工業廠房（聽流行/搖滾，力量感）：
  # factoryhall = "${irDir}/Factory Hall.wav";

  # 🌲 5. 森林自然聲場（完全無牆壁壓迫感，極致通透）：
  # Forest2 = "${irDir}/Forest 2.wav";

  # 🎙️ 6. 機皇金色大廳（你最愛的原汁原味）：
  hallIrFile = "${irDir}/05Hall5.wav";
  sofaFile   = "/home/rhys/DOwn/EAsyeffects-main/dtf_nh2.sofa";
in
{
  # 1. 內核硬實時權限
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "95"; }
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "nice";    type = "-"; value = "-19"; }
  ];

  users.users.rhys.extraGroups = [ "audio" ];
  services.pulseaudio.enable = false;

  # 2. PipeWire 核心服務
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # ⭐️ 官方正統宣告：自動合成 pipewire-ladspa-plugins 並注入後台服務！
    extraLadspaPackages = [ pkgs.ladspaPlugins ];

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
        {
          matches = [ { "node.name" = "alsa_input.pci-0000_00_1b.0.pro-input-0"; } ];
          actions = {
            update-props = {
              "priority.driver" = 2000;
              "priority.session" = 2000;
            };
          };
        }
        {
          matches = [
            { "node.name" = "alsa_output.pci-0000_00_1b.0.pro-output-1"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-3"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-7"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-8"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-10"; }
            { "node.name" = "alsa_output.pci-0000_04_00.1.pro-output-11"; }
            # { "node.name" = "alsa_input.pci-0000_00_1b.0.pro-input-2"; }
          ];
          actions = { update-props = { "node.disabled" = true; }; };
        }
      ];
    };

    # =======================================================
    # 🎚️ 錄音棚全家桶效果器機架（全立體聲 FL/FR 對齊）
    # =======================================================
    extraConfig.pipewire."99-studio-modules" = {
      "context.modules" = [
        # 1. 立體聲 EQ（內置）
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "FX · EQ · PARAMETRIC";
            "media.name" = "Studio_Vocal_EQ";
            "filter.graph" = {
              nodes = [
                { type = "builtin"; label = "bq_highpass"; name = "hp_l"; control = { "Freq" = 80.0; "Q" = 0.707; }; }
                { type = "builtin"; label = "bq_peaking"; name = "presence_l"; control = { "Freq" = 3000.0; "Q" = 1.0; "Gain" = 2.5; }; }
                { type = "builtin"; label = "bq_highpass"; name = "hp_r"; control = { "Freq" = 80.0; "Q" = 0.707; }; }
                { type = "builtin"; label = "bq_peaking"; name = "presence_r"; control = { "Freq" = 3000.0; "Q" = 1.0; "Gain" = 2.5; }; }
              ];
              links = [
                { output = "hp_l:Out"; input = "presence_l:In"; }
                { output = "hp_r:Out"; input = "presence_r:In"; }
              ];
              inputs = [ "hp_l:In" "hp_r:In" ];
              outputs = [ "presence_l:Out" "presence_r:Out" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = { "node.name" = "Studio_EQ_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_EQ_Out"; "node.passive" = true; };
          };
        }

        # 2. 經典 SC4 立體聲壓縮器（LADSPA）
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "FX · COMP · VOCAL";
            "media.name" = "Studio_Vocal_Compressor";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "sc4_1882";
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
              inputs = [ "sc4:Left input" "sc4:Right input" ];
              outputs = [ "sc4:Left output" "sc4:Right output" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = { "node.name" = "Studio_Compressor_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_Compressor_Out"; "node.passive" = true; };
          };
        }

        # 3. 雙聲道噪聲門限器（LADSPA 立體聲）
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "FX · GATE · Noise";
            "media.name" = "Studio_Noise_Gate";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "gate_1410";
                  label = "gate";
                  name = "gate_l";
                  control = { "Threshold (dB)" = -40.0; "Attack (ms)" = 2.0; "Hold (ms)" = 50.0; "Decay (ms)" = 100.0; "Range (dB)" = -90.0; };
                }
                {
                  type = "ladspa";
                  plugin = "gate_1410";
                  label = "gate";
                  name = "gate_r";
                  control = { "Threshold (dB)" = -40.0; "Attack (ms)" = 2.0; "Hold (ms)" = 50.0; "Decay (ms)" = 100.0; "Range (dB)" = -90.0; };
                }
              ];
              inputs = [ "gate_l:Input" "gate_r:Input" ];
              outputs = [ "gate_l:Output" "gate_r:Output" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = { "node.name" = "Studio_Gate_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_Gate_Out"; "node.passive" = true; };
          };
        }

        # 4. 雙聲道電子管溫暖飽和器（LADSPA 立體聲）
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "FX · TUBE · WARMTH";
            "media.name" = "Studio_Tube_Warmth";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "valve_1209";
                  label = "valve";
                  name = "valve_l";
                  control = { "Distortion character" = 0.4; "Distortion level" = 0.0; };
                }
                {
                  type = "ladspa";
                  plugin = "valve_1209";
                  label = "valve";
                  name = "valve_r";
                  control = { "Distortion character" = 0.4; "Distortion level" = 0.0; };
                }
              ];
              inputs = [ "valve_l:Input" "valve_r:Input" ];
              outputs = [ "valve_l:Output" "valve_r:Output" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = { "node.name" = "Studio_Tube_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_Tube_Out"; "node.passive" = true; };
          };
        }

        # 5. 磚牆防爆限制器（LADSPA）
        # {
        #   name = "libpipewire-module-filter-chain";
        #   flags = [ "ifexists" "nofail" ];
        #   args = {
        #     "node.description" = "FX · LIMITER · MASTER";
        #     "media.name" = "Studio_Brickwall_Limiter";
        #     "filter.graph" = {
        #       nodes = [
        #         {
        #           type = "ladspa";
        #           plugin = "fast_lookahead_limiter_1913";
        #           label = "fastLookaheadLimiter";
        #           name = "fastLookaheadLimiter";
        #           control = {
        #             "Input gain (dB)" = 0.0;
        #             "Limit (dB)" = -0.5;
        #             "Release time (s)" = 0.05;
        #           };
        #         }
        #       ];
        #       inputs = [ "fastLookaheadLimiter:Input 1" "fastLookaheadLimiter:Input 2" ];
        #       outputs = [ "fastLookaheadLimiter:Output 1" "fastLookaheadLimiter:Output 2" ];
        #     };
        #     "audio.position" = [ "FL" "FR" ];
        #     "capture.props" = { "node.name" = "Studio_Limiter_In"; "media.class" = "Audio/Sink"; };
        #     "playback.props" = { "node.name" = "Studio_Limiter_Out"; "node.passive" = true; };
        #   };
        # }
        #
        # 6. SOFA 虛擬雙耳監聽音箱（使用你的 dtf_nh2.sofa）
{
        "filter.graph" = {
  nodes = [
    {
      type = "builtin";
      name = "limiter";
      label = "linear";
      control = {
        "Mult" = 1.0;
      };
    }
  ];
};
}
        
        # SOFA SOFA SOFA SOFA SOFA SOFA SOFA SOFA SOFA
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "FX · SOFA · MONITORS";
            "media.name" = "Studio_SOFA_Monitors";
            "filter.graph" = {
              nodes = [
                {
                  type = "sofa";
                  label = "spatializer";
                  name = "spFL";
                  config = { filename = sofaFile; };
                  control = { "Azimuth" = 30.0; "Elevation" = 0.0; "Radius" = 1.2; };
                }
                {
                  type = "sofa";
                  label = "spatializer";
                  name = "spFR";
                  config = { filename = sofaFile; };
                  control = { "Azimuth" = 330.0; "Elevation" = 0.0; "Radius" = 1.2; };
                }
                { type = "builtin"; label = "mixer"; name = "mixL"; }
                { type = "builtin"; label = "mixer"; name = "mixR"; }
              ];
              links = [
                { output = "spFL:Out L"; input = "mixL:In 1"; }
                { output = "spFL:Out R"; input = "mixR:In 1"; }
                { output = "spFR:Out L"; input = "mixL:In 2"; }
                { output = "spFR:Out R"; input = "mixR:In 2"; }
              ];
              inputs = [ "spFL:In" "spFR:In" ];
              outputs = [ "mixL:Out" "mixR:Out" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = { "node.name" = "Studio_SOFA_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_SOFA_Out"; "node.passive" = true; };
          };
        }

        # ⭐️ 卷积器 2：耳机虚拟音箱空间化（串联在耳机前，彻底消除压迫感）
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "OUT · STUDIO · MONITOR";
            "media.name" = "Studio_Monitor_Spatializer";
            "filter.graph" = {
              nodes = [
                # 加载你的虚拟音箱空间脉冲 WAV 文件（例如 HeSuVi 或监听室双耳脉冲）
                { type = "builtin"; label = "convolver"; name = "spatFL"; config = { filename = Schellingwoude; channel = 0; gain = 1.0; }; }
                { type = "builtin"; label = "convolver"; name = "spatFR"; config = { filename = Schellingwoude; channel = 1; gain = 1.0; }; }
              ];
              inputs = [ "spatFL:In" "spatFR:In" ];
              outputs = [ "spatFL:Out" "spatFR:Out" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = { "node.name" = "Studio_Spatial_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = {
              "node.name" = "Studio_Spatial_Out";
              "node.passive" = true;
              # 直通你的物理耳机声卡
              "target.object" = "alsa_output.pci-0000_00_1b.0.pro-output-0";
            };
          };
        }

        # =======================================================
        # 🚀 模組：聽不清救星！500%~1000% 超級音頻放大器（帶防爆保護）
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "SuperAudio · 500% - 1000%";
            "media.name" = "Audio_Booster";
            "filter.graph" = {
              nodes = [
                # ⭐️ 1. 純線性硬件級放大（Mult = 5.0 代表基礎放大 500%，可改為 10.0 即 1000%）
                {
                  type = "builtin";
                  label = "linear";
                  name = "amp_l";
                  control = { "Mult" = 5.0; };
                }
                {
                  type = "builtin";
                  label = "linear";
                  name = "amp_r";
                  control = { "Mult" = 5.0; };
                }

                # ⭐️ 2. 串聯磚牆限制器：把小聲拉大，但死守 -0.5dB 物理防爆天花板！
                {
                  type = "ladspa";
                  plugin = "fast_lookahead_limiter_1913";
                  label = "fastLookaheadLimiter";
                  name = "limiter";
                  control = {
                    "Input gain (dB)" = 0.0;
                    "Limit (dB)" = -0.5;
                    "Release time (s)" = 0.05;
                  };
                }
              ];

              # 放大後自動進限制器過濾
              links = [
                { output = "amp_l:Out"; input = "limiter:Input 1"; }
                { output = "amp_r:Out"; input = "limiter:Input 2"; }
              ];

              inputs = [ "amp_l:In" "amp_r:In" ];
              outputs = [ "limiter:Output 1" "limiter:Output 2" ];
            };

            "audio.position" = [ "FL" "FR" ];
            "capture.props" = {
              "node.name" = "Audio_Booster_In";
              "media.class" = "Audio/Sink";
            };
            "playback.props" = {
              "node.name" = "Audio_Booster_Out";
              "node.passive" = true;
            };
          };
        }

        
        # =======================================================
        # FX · DELAY · STUDIO
        # Stereo Studio Delay
        # L = 280ms / R = 420ms
        # Dry 70% / Wet 30%
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "FX · DELAY · STUDIO";
            "media.name" = "FX_DELAY_STUDIO";

            "filter.graph" = {
              nodes = [
                # -------------------------
                # LEFT
                # -------------------------
                {
                  type = "builtin";
                  label = "copy";
                  name = "delay_dry_l";
                }

                {
                  type = "builtin";
                  label = "delay";
                  name = "delay_l";
                  config = {
                    "max-delay" = 2.0;
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

                # -------------------------
                # RIGHT
                # -------------------------
                {
                  type = "builtin";
                  label = "copy";
                  name = "delay_dry_r";
                }

                {
                  type = "builtin";
                  label = "delay";
                  name = "delay_r";
                  config = {
                    "max-delay" = 2.0;
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
                # LEFT
                { output = "delay_dry_l:Out"; input = "delay_mix_l:In 1"; }
                { output = "delay_l:Out";     input = "delay_mix_l:In 2"; }

                # RIGHT
                { output = "delay_dry_r:Out"; input = "delay_mix_r:In 1"; }
                { output = "delay_r:Out";     input = "delay_mix_r:In 2"; }
              ];

              inputs = [
                "delay_dry_l:In"
                "delay_l:In"
                "delay_dry_r:In"
                "delay_r:In"
              ];

              outputs = [
                "delay_mix_l:Out"
                "delay_mix_r:Out"
              ];
            };

            "audio.position" = [ "FL" "FR" ];

            "capture.props" = {
              "node.name" = "FX_DELAY_STUDIO_In";
              "media.class" = "Audio/Sink";
            };

            "playback.props" = {
              "node.name" = "FX_DELAY_STUDIO_Out";
              "node.passive" = true;
            };
          };
        }

        # =======================================================
        # FX · CHORUS · STUDIO
        # SWH Multivoice Chorus
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "FX · CHORUS · STUDIO";
            "media.name" = "FX_CHORUS_STUDIO";

            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "chorus_l";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/multivoice_chorus_1201.so";
                  label = "multivoiceChorus";

                  control = {
                    "Number of voices" = 3.0;
                    "Delay base (ms)" = 20.0;
                    "Voice separation (ms)" = 0.5;
                    "Detune (%)" = 1.0;
                    "LFO frequency (Hz)" = 5.0;
                    "Output attenuation (dB)" = -3.0;
                  };
                }

                {
                  type = "ladspa";
                  name = "chorus_r";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/multivoice_chorus_1201.so";
                  label = "multivoiceChorus";

                  control = {
                    "Number of voices" = 3.0;
                    "Delay base (ms)" = 20.0;
                    "Voice separation (ms)" = 0.5;
                    "Detune (%)" = 1.0;
                    "LFO frequency (Hz)" = 5.0;
                    "Output attenuation (dB)" = -3.0;
                  };
                }
              ];

              inputs = [
                "chorus_l:Input"
                "chorus_r:Input"
              ];

              outputs = [
                "chorus_l:Output"
                "chorus_r:Output"
              ];
            };

            "audio.position" = [ "FL" "FR" ];

            "capture.props" = {
              "node.name" = "FX_CHORUS_STUDIO_In";
              "media.class" = "Audio/Sink";
            };

            "playback.props" = {
              "node.name" = "FX_CHORUS_STUDIO_Out";
              "node.passive" = true;
            };
          };
        }

        # =======================================================
        # FX · FLANGER · STUDIO
        # SWH Flanger
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "FX · FLANGER · STUDIO";
            "media.name" = "FX_FLANGER_STUDIO";

            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "flanger_l";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/flanger_1191.so";
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
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/flanger_1191.so";
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

            "audio.position" = [ "FL" "FR" ];

            "capture.props" = {
              "node.name" = "FX_FLANGER_STUDIO_In";
              "media.class" = "Audio/Sink";
            };

            "playback.props" = {
              "node.name" = "FX_FLANGER_STUDIO_Out";
              "node.passive" = true;
            };
          };
        }

        # =======================================================
        # FX · PHASER · STUDIO
        # SWH LFO Phaser
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "FX · PHASER · STUDIO";
            "media.name" = "FX_PHASER_STUDIO";

            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "phaser_l";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/phasers_1217.so";
                  label = "lfoPhaser";
                }

                {
                  type = "ladspa";
                  name = "phaser_r";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/phasers_1217.so";
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

            "audio.position" = [ "FL" "FR" ];

            "capture.props" = {
              "node.name" = "FX_PHASER_STUDIO_In";
              "media.class" = "Audio/Sink";
            };

            "playback.props" = {
              "node.name" = "FX_PHASER_STUDIO_Out";
              "node.passive" = true;
            };
          };
        }

        # =======================================================
        # FX · DE-ESSER · VOCAL
        # Calf LV2 Deesser
        # =======================================================
        # {
        #   name = "libpipewire-module-filter-chain";
        #   flags = [ "ifexists" "nofail" ];
        #   args = {
        #     "node.description" = "FX · DE-ESSER · VOCAL";
        #     "media.name" = "FX_DE_ESSER_VOCAL";

        #     "filter.graph" = {
        #       nodes = [
        #         {
        #           type = "lv2";
        #           name = "deesser";
        #           plugin = "http://calf.sourceforge.net/plugins/Deesser";

        #           control = {
        #             "threshold" = 0.009375;
        #           };
        #         }
        #       ];

        #       inputs = [
        #         "deesser:In L"
        #         "deesser:In R"
        #       ];

        #       outputs = [
        #         "deesser:Out L"
        #         "deesser:Out R"
        #       ];
        #     };

        #     "audio.position" = [ "FL" "FR" ];

        #     "capture.props" = {
        #       "node.name" = "FX_DE_ESSER_VOCAL_In";
        #       "media.class" = "Audio/Sink";
        #     };

        #     "playback.props" = {
        #       "node.name" = "FX_DE_ESSER_VOCAL_Out";
        #       "node.passive" = true;
        #     };
        #   };
        # }

        # =======================================================
        # 🎸 破音模組 1：硬裁剪失真（Hard Clipper 立體聲版）
        # 效果：直接把波形強制削頂，產生極其粗暴、帶磁性的喇叭撕裂破音
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "🔥 OVERDRIVE · HARD CLIPPER";
            "media.name" = "Studio_Overdrive";
            "filter.graph" = {
              nodes = [
                # 左聲道過載鏈：前級推大 (Gain) -> 軟/硬裁剪失真 (bq_peaking 激增波形)
                { type = "builtin"; label = "linear"; name = "drive_l"; control = { "Mult" = 3.0; }; } # 推大 3 倍進去過載
                { type = "builtin"; label = "bq_peaking"; name = "clip_l"; control = { "Freq" = 1500.0; "Q" = 0.5; "Gain" = 12.0; }; } # 高增益染色

                # 右聲道過載鏈
                { type = "builtin"; label = "linear"; name = "drive_r"; control = { "Mult" = 3.0; }; }
                { type = "builtin"; label = "bq_peaking"; name = "clip_r"; control = { "Freq" = 1500.0; "Q" = 0.5; "Gain" = 12.0; }; }
              ];
              links = [
                { output = "drive_l:Out"; input = "clip_l:In"; }
                { output = "drive_r:Out"; input = "clip_r:In"; }
              ];
              inputs = [ "drive_l:In" "drive_r:In" ];
              outputs = [ "clip_l:Out" "clip_r:Out" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = { "node.name" = "Studio_Overdrive_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_Overdrive_Out"; "node.passive" = true; };
          };
        }

                # =======================================================
        # 🎸 破音模組 2：SWH Diode
        # 二极管非线性失真
        # Mode:
        #   0 = None
        #   1 = Half Wave
        #   2 = Full Wave
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "🔥 OVERDRIVE · DIODE";
            "media.name" = "SWH_Diode";

            "filter.graph" = {
              nodes = [
                # 左声道
                {
                  type = "ladspa";
                  name = "diode_l";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/diode_1185.so";
                  label = "diode";
                  control = {
                    "Mode (0 for none, 1 for half wave, 2 for full wave)" = 2.0;
                  };
                }

                # 右声道
                {
                  type = "ladspa";
                  name = "diode_r";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/diode_1185.so";
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

            "audio.position" = [ "FL" "FR" ];

            "capture.props" = {
              "node.name" = "SWH_Diode_In";
              "media.class" = "Audio/Sink";
            };

            "playback.props" = {
              "node.name" = "SWH_Diode_Out";
              "node.passive" = true;
            };
          };
        }


        # =======================================================
        # 🎸 破音模組 3：SWH FOverdrive
        # Fast Overdrive
        # Drive level：1.0 ～ 3.0
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "🔥 OVERDRIVE · FAST DRIVE";
            "media.name" = "SWH_FOverdrive";

            "filter.graph" = {
              nodes = [
                # 左声道
                {
                  type = "ladspa";
                  name = "foverdrive_l";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/foverdrive_1196.so";
                  label = "foverdrive";
                  control = {
                    "Drive level" = 2.0;
                  };
                }

                # 右声道
                {
                  type = "ladspa";
                  name = "foverdrive_r";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/foverdrive_1196.so";
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

            "audio.position" = [ "FL" "FR" ];

            "capture.props" = {
              "node.name" = "SWH_FOverdrive_In";
              "media.class" = "Audio/Sink";
            };

            "playback.props" = {
              "node.name" = "SWH_FOverdrive_Out";
              "node.passive" = true;
            };
          };
        }


        # =======================================================
        # 🎸 破音模組 4：SWH Valve
        # Valve Saturation / 真空管饱和
        #
        # Distortion level     = 0.0 ～ 1.0
        # Distortion character = 0.0 ～ 1.0
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "🔥 OVERDRIVE · TUBE SATURATION";
            "media.name" = "SWH_Valve";

            "filter.graph" = {
              nodes = [
                # 左声道
                {
                  type = "ladspa";
                  name = "valve_l";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/valve_1209.so";
                  label = "valve";
                  control = {
                    "Distortion level" = 0.50;
                    "Distortion character" = 0.50;
                  };
                }

                # 右声道
                {
                  type = "ladspa";
                  name = "valve_r";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/valve_1209.so";
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

            "audio.position" = [ "FL" "FR" ];

            "capture.props" = {
              "node.name" = "SWH_Valve_In";
              "media.class" = "Audio/Sink";
            };

            "playback.props" = {
              "node.name" = "SWH_Valve_Out";
              "node.passive" = true;
            };
          };
        }


        # =======================================================
        # 🎸 破音模組 5：SWH Valve Rectifier
        # 真空管整流器 + Sag + Distortion
        #
        # Sag level  = 0.0 ～ 1.0
        # Distortion = 0.0 ～ 1.0
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "🔥 OVERDRIVE · TUBE RECTIFIER";
            "media.name" = "SWH_ValveRect";

            "filter.graph" = {
              nodes = [
                # 左声道
                {
                  type = "ladspa";
                  name = "valve_rect_l";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/valve_rect_1405.so";
                  label = "valveRect";
                  control = {
                    "Sag level" = 0.50;
                    "Distortion" = 0.50;
                  };
                }

                # 右声道
                {
                  type = "ladspa";
                  name = "valve_rect_r";
                  plugin = "/nix/store/w08qzpb0qqr5qxx0gkbwscar6y244k1n-pipewire-ladspa-plugins/lib/ladspa/valve_rect_1405.so";
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

            "audio.position" = [ "FL" "FR" ];

            "capture.props" = {
              "node.name" = "SWH_ValveRect_In";
              "media.class" = "Audio/Sink";
            };

            "playback.props" = {
              "node.name" = "SWH_ValveRect_Out";
              "node.passive" = true;
            };
          };
        }
        
        # 7. 純大廳混響（你的 05Hall5）
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "Fokke van Saane Hall5";
            "media.name" = "Hall5 Wet Reverb";
            "filter.graph" = {
              nodes = [
                { type = "builtin"; label = "convolver"; name = "convFL"; config = { filename = hallIrFile; channel = 0; gain = 1.0; }; }
                { type = "builtin"; label = "convolver"; name = "convFR"; config = { filename = hallIrFile; channel = 1; gain = 1.0; }; }
              ];
              inputs = [ "convFL:In" "convFR:In" ];
              outputs = [ "convFL:Out" "convFR:Out" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = { "node.name" = "Hall5_Soundstage_Sink"; "media.class" = "Audio/Sink"; };
            "playback.props" = {
              "node.name" = "Hall5_Soundstage_Output";
              "node.passive" = true;
              "target.object" = "alsa_output.pci-0000_00_1b.0.pro-output-0";
            };
          };
        }
      ];
    };
  };

# EQ	频率塑形、削减共振	FX · EQ · PARAMETRIC
# Compressor	动态压缩，让音量更稳定	FX · COMP · STUDIO
# Limiter	防止峰值爆音、母线保护	FX · LIMITER · MASTER
# Gate	消除底噪、控制无声段	FX · GATE · STUDIO
# Delay	回声、空间感、节奏效果	FX · DELAY · STUDIO
# Reverb	房间、Hall、Plate 等空间	FX · REVERB · STUDIO
# Chorus	加宽、复制/调制声音	FX · CHORUS · STUDIO
# Flanger	金属扫频、特殊空间感	FX · FLANGER · STUDIO
# Phaser	相位旋转效果	FX · PHASER · STUDIO

  # 3. 系統工具
  environment.systemPackages = with pkgs; [
    pipewire
    qpwgraph
    pavucontrol
    ladspaPlugins
  ];
}
