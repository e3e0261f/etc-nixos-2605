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
            "node.description" = "Studio Vocal EQ (Stereo)";
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
            "node.description" = "Studio Noise Gate (Stereo)";
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
            "node.description" = "Studio Tube Warmth (Stereo)";
            "media.name" = "Studio_Tube_Warmth";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "valve_1209";
                  label = "valve";
                  name = "valve_l";
                  control = { "Warmth level" = 0.4; "Distortion level" = 0.0; };
                }
                {
                  type = "ladspa";
                  plugin = "valve_1209";
                  label = "valve";
                  name = "valve_r";
                  control = { "Warmth level" = 0.4; "Distortion level" = 0.0; };
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
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "Studio Brickwall Limiter";
            "media.name" = "Studio_Brickwall_Limiter";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "fast_lookahead_limiter_1913";
                  label = "fastLookaheadLimiter";
                  control = {
                    "Input gain (dB)" = 0.0;
                    "Limit (dB)" = -0.5;
                    "Release time (s)" = 0.05;
                  };
                }
              ];
              inputs = [ "fastLookaheadLimiter:Input 1" "fastLookaheadLimiter:Input 2" ];
              outputs = [ "fastLookaheadLimiter:Output 1" "fastLookaheadLimiter:Output 2" ];
            };
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = { "node.name" = "Studio_Limiter_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_Limiter_Out"; "node.passive" = true; };
          };
        }

        # 6. SOFA 虛擬雙耳監聽音箱（使用你的 dtf_nh2.sofa）
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "Studio SOFA Virtual Monitors";
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
            "node.description" = "Virtual Studio Monitor Spatializer";
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
            "node.description" = "Super Audio Booster (500% - 1000%)";
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
        # 🎸 破音/過載模組 1：硬裁剪失真（Hard Clipper）
        # 效果：直接把波形削顶，产生极其粗暴、带磁性的“喇叭撕裂破音”
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "Studio Hard Clipper (Distortion)";
            "media.name" = "Studio_Hard_Clipper";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "hard_clipper_1433";
                  label = "hardClipper";
                  control = {
                    "Clipping level (dB)" = -6.0; # 閥值越低，破音越慘烈（可調至 -15dB 體驗極度失真）
                  };
                }
              ];
              inputs = [ "hardClipper:Input" ];
              outputs = [ "hardClipper:Output" ];
            };
            "capture.props" = { "node.name" = "Studio_Clipper_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_Clipper_Out"; "node.passive" = true; };
          };
        }

        # =======================================================
        # 🎸 破音/過載模組 2：數碼降採樣破音（Decimator / Bitcrusher）
        # 效果：制造 8-bit 复古游戏机、对讲机、机械人、数码断流的电子碎裂感
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "Studio Bitcrusher / Decimator";
            "media.name" = "Studio_Decimator";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "decimator_1202";
                  label = "decimator";
                  control = {
                    "Bit depth" = 6.0;          # 壓低位深（4bit ~ 8bit 產生強烈數碼破音）
                    "Sample rate (Hz)" = 8000.0; # 降低採樣率（產生粗糙的電話/對講機質感）
                  };
                }
              ];
              inputs = [ "decimator:Input" ];
              outputs = [ "decimator:Output" ];
            };
            "capture.props" = { "node.name" = "Studio_Decimator_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_Decimator_Out"; "node.passive" = true; };
          };
        }

        # =======================================================
        # 🎸 破音/過載模組 3：二極管過載器（Diode Overdrive / 模擬吉他失真）
        # 效果：模擬真實吉他過載踏板，產生温暖但颗粒感十足的模拟失真
        # =======================================================
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "ifexists" "nofail" ];
          args = {
            "node.description" = "Studio Diode Overdrive";
            "media.name" = "Studio_Diode_Overdrive";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "diodes_1409";
                  label = "diodes";
                  control = {
                    "Drive" = 5.0; # 推力越大，过载失真越猛
                  };
                }
              ];
              inputs = [ "diodes:Input" ];
              outputs = [ "diodes:Output" ];
            };
            "capture.props" = { "node.name" = "Studio_Overdrive_In"; "media.class" = "Audio/Sink"; };
            "playback.props" = { "node.name" = "Studio_Overdrive_Out"; "node.passive" = true; };
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

  # 3. 系統工具
  environment.systemPackages = with pkgs; [
    pipewire
    qpwgraph
    pavucontrol
    ladspaPlugins
  ];
}
