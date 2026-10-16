
# /etc/nixos/modules/defaults.nix
{ pkgs, ... }:

{
  # =======================================================
  # ⭐️ 1. XDG MIME 檔案與協定預設關聯（全系統標準）
  # =======================================================
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # ⭐️ 預設瀏覽器：Google Chrome
      "text/html"                 = "google-chrome.desktop";
      "x-scheme-handler/http"     = "google-chrome.desktop";
      "x-scheme-handler/https"    = "google-chrome.desktop";
      "x-scheme-handler/about"    = "google-chrome.desktop";
      "x-scheme-handler/unknown"  = "google-chrome.desktop";

      # ⭐️ 預設檔案管理器：Nemo (點擊資料夾、下載完成打開資料夾)
      "inode/directory"           = "nemo.desktop";

      # 預設多媒體播放器：VLC
      "audio/x-wav"               = "vlc.desktop";
      "audio/vnd.wave"            = "vlc.desktop";
      "audio/flac"                = "vlc.desktop";
      "audio/mpeg"                = "vlc.desktop";
      "video/mp4"                 = "vlc.desktop";
      "video/x-matroska"          = "vlc.desktop";

      # 預設壓縮檔管理器：Ark
      "application/zip"           = "org.kde.ark.desktop";
      "application/x-tar"         = "org.kde.ark.desktop";
      "application/x-7z-compressed" = "org.kde.ark.desktop";
      "application/x-rar"         = "org.kde.ark.desktop";
    };
  };

  # =======================================================
  # ⭐️ 2. 全域環境變數預設值 (終端機與守護程序)
  # =======================================================
  home.sessionVariables = {
    BROWSER     = "google-chrome";
    FILEMANAGER = "nemo";
    EDITOR      = "hx";
    VISUAL      = "hx";
  };
}
