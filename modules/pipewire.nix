# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

let
  hallIrFile = "/home/rhys/DOwn/EAsyeffects-main/FokkevanSaane/05Hall5.wav";

  # ⭐️【在此調節濕音比例！】
  # 0.10 ≈ -20dB（微弱空氣感，極度清澈通透）
  # 0.18 ≈ -15dB（黃金聽歌聲場，相當於 EasyEffects 的推薦默認值）
  # 0.30 ≈ -10dB（濃郁大廳空靈感）
  wetLevel = 0.50;
in
{
  # 前面的 security 與 services.pipewire 基礎設置保持不變 ...

  services.pipewire.extraConfig.pipewire."99-hall-reverb" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Fokke van Saane Hall5 (Dry/Wet Mix)";
          "media.name" = "Fokke van Saane Hall5";
          "filter.graph" = {
            nodes = [
              # 1. 複製節點：將左右聲道音訊一分為二（一路走乾聲，一路進混響）
              { type = "builtin"; label = "copy"; name = "copy_fl"; }
              { type = "builtin"; label = "copy"; name = "copy_fr"; }

              # 2. 卷積器：計算大廳殘響，並通過 gain 嚴格控制濕聲音量！
              {
                type = "builtin";
                name = "conv_fl";
                label = "convolver";
                config = {
                  filename = hallIrFile;
                  channel = 0;
                  gain = wetLevel; # ⭐️ 左聲道濕音增益
                };
              }
              {
                type = "builtin";
                name = "conv_fr";
                label = "convolver";
                config = {
                  filename = hallIrFile;
                  channel = 1;
                  gain = wetLevel; # ⭐️ 右聲道濕音增益
                };
              }

              # 3. 內置混音器：把 100% 原始乾聲 與 衰減後的濕音 融為一體輸出
              { type = "builtin"; label = "mixer"; name = "mix_fl"; }
              { type = "builtin"; label = "mixer"; name = "mix_fr"; }
            ];

            links = [
              # --- 左聲道線路 ---
              # 原聲乾聲直達混音器（保持 100% 原汁原味清晰度）
              { output = "copy_fl:Out"; input = "mix_fl:In 1"; }
              # 濕聲走卷積器運算後進入混音器
              { output = "copy_fl:Out"; input = "conv_fl:In"; }
              { output = "conv_fl:Out"; input = "mix_fl:In 2"; }

              # --- 右聲道線路 ---
              # 原聲乾聲直達混音器
              { output = "copy_fr:Out"; input = "mix_fr:In 1"; }
              # 濕聲走卷積器運算後進入混音器
              { output = "copy_fr:Out"; input = "conv_fr:In"; }
              { output = "conv_fr:Out"; input = "mix_fr:In 2"; }
            ];

            inputs = [ "copy_fl:In" "copy_fr:In" ];
            outputs = [ "mix_fl:Out" "mix_fr:Out" ];
          };

          "audio.position" = [ "FL" "FR" ];
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
}
