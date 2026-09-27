# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # =======================================================
    # 🎙️ 發燒級低延遲架構（修復爆音與 buffer 被劫持問題）
    # =======================================================
    extraConfig.pipewire."99-studio-extreme" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];

        # ⭐️ 日常黃金緩衝區：
        # 如果掛載 EasyEffects 卷積，512 (10.6ms) 是零爆音的最優甜點；純音訊可挑戰 256
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 1024;

        # ⭐️ 核心修正 1：焊死物理天花板！徹底禁止任何應用把系統拉爆到 2048/4096
        "default.clock.quantum-limit" = 1024;

        # ⭐️ 核心修正 2：重採樣品質改為 6 或 7（發燒黃金平衡）
        # Quality 10 在實時卷積下是 CPU 災難；Quality 6-7 的動態範圍已超過 140dB（超越人類聽覺極限），且零 Xrun
        "resample.quality" = 6;
      };
    };

    extraConfig.pipewire-pulse."99-studio-pulse" = {
      "context.properties" = {
        "resample.quality" = 6;
      };
      "pulse.properties" = {
        # ⭐️ 核心修正 3：給 Spotify 的請求戴上緊箍咒
        "pulse.min.req" = "256/48000";
        "pulse.default.req" = "512/48000";
        "pulse.max.req" = "1024/48000";       # 禁止 Spotify 要求超大 tlength
        "pulse.min.quantum" = "256/48000";
        "pulse.max.quantum" = "1024/48000";   # 限制 Pulse 最大量子
      };
    };

    wireplumber.extraConfig."10-disable-suspension" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = "~alsa_output.*"; } ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };

  # 2. 確保系統已安裝 easyeffects
  environment.systemPackages = [ pkgs.easyeffects ];

  # 3. EasyEffects 生命週期管理
  systemd.user.services.easyeffects = {
    description = "EasyEffects Audio Daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "pipewire.service" "graphical-session.target" ];
    after = [ "pipewire.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };
}
