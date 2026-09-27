# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

let
  hallIrFile = "/home/rhys/DOwn/EAsyeffects-main/FokkevanSaane/05Hall5.wav";
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
            { "node.name" = "alsa_input.pci-0000_00_1b.0.pro-input-2"; }
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
