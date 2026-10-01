        { pkgs, ... }:

{
  # --- 核心軟體包 ---
  environment.systemPackages = with pkgs; [
    tuigreet
  ];

  # ============================================================
  # 1. 靜默引導與日誌壓制（禁止開機服務向螢幕亂打狀態）
  # ============================================================
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    # "quiet"
    "loglevel=3"
    "systemd.show_status=false"
    # "systemd.show_status=auto" # ⭐️ 禁止 systemd 輸出 [ OK ] Started dae.service
    # "rd.udev.log_level=3"
  ];

  # ============================================================
  # 2. Greetd 配置
  # ============================================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # 保留你的 Matrix 綠雨動效與啟動命令
        command = "${pkgs.tuigreet}/bin/tuigreet --background matrix --background-fps 30 --matrix-colors '#CCFFCC,#33FF66,#006622' --matrix-speed 1,2 --time --remember --asterisks --cmd 'uwsm start default'";
        user = "greeter";
      };
    };
  };

  # # ============================================================
  # # 3. 核心修復：徹底清空 VT1 螢幕，杜絕任何文字干擾
  # # ============================================================
  # systemd.services.greetd.serviceConfig = {
  #   # Type = "idle"; # ⭐️ 等後台服務（如 dae）就緒後再繪製介面
  #   StandardInput = "tty";
  #   StandardOutput = "tty";
  #   StandardError = "journal"; # 錯誤訊息進 journal 日誌，絕不噴到螢幕

  #   # ⭐️ 核心三件套：啟動 tuigreet 前瞬間清空 VT1 螢幕上的所有殘留文字
  #   TTYReset = true;
  #   TTYVHangup = true;
  #   TTYVTDisallocate = true;
  # };

  # --- 系統底層優化 ---
  # services.getty.autologinUser = null; # 確保禁用自動登錄，由 greetd 接管
}

