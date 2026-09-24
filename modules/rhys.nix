# /etc/nixos/modules/rhys.nix
{ pkgs, ... }:

let
  rhysCommand = pkgs.writeShellScriptBin "rhys" ''
    #!/usr/bin/env bash

    # ANSI 顏色定義
    C_CYAN="\033[1;36m"
    C_GREEN="\033[1;32m"
    C_YELLOW="\033[1;33m"
    C_BLUE="\033[1;34m"
    C_PURPLE="\033[1;35m"
    C_RED="\033[1;31m"
    C_WHITE="\033[1;37m"
    C_GRAY="\033[0;90m"
    C_BOLD="\033[1m"
    C_RESET="\033[0m"

    show_header() {
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
      echo -e "  🚀 ''${C_WHITE}RHYS · NIXOS 專屬全系統極客百科與指揮中心''${C_RESET} ''${C_GRAY}(v198 Pro Edition)''${C_RESET}"
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
    }

    # 1. 檔案與模組分布地圖 (rhys files / rhys -f)
    show_files() {
      show_header
      echo -e "\n''${C_PURPLE}📂 【系統核心與模組架構地圖 (/etc/nixos/)】''${C_RESET}"
      echo -e "  ''${C_WHITE}/etc/nixos/''${C_RESET}"
      echo -e "  ''${C_GRAY}├──''${C_RESET} ''${C_GREEN}configuration.nix''${C_RESET}    : 系統第 0 級基礎設施 (Zen內核, 限制30核編譯, RT優先級99, 禁用IPv6)"
      echo -e "  ''${C_GRAY}├──''${C_RESET} ''${C_GREEN}hardware-configuration.nix''${C_RESET}: 磁碟分割區 (XFS), LUKS 加密 UUID, systemd-boot"
      echo -e "  ''${C_GRAY}├──''${C_RESET} ''${C_GREEN}flake.nix / flake.lock''${C_RESET}  : Flakes 宣告式根入口、Quickshell/Caelestia 鎖定"
      echo -e "  ''${C_GRAY}└──''${C_RESET} ''${C_WHITE}modules/''${C_RESET}               : 模組化子目錄 (責任分離)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}home.nix''${C_RESET}            : Home Manager 總管 (注入 QS_ICON_THEME=Papirus-Dark)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}dae-h3.nix''${C_RESET}          : eBPF 內核透明代理 (DoH3, cheap/google_ai/premium三級節點池)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}pipewire.nix''${C_RESET}        : R5E SupremeFX 錄音棚極限 (Quantum 256 @ 5.3ms, 防掛起保活)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}hyprland.nix''${C_RESET}        : Hyprland 視窗規則、Caelestia drawers 快捷鍵綁定"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}waybar.nix''${C_RESET}          : 3D 水晶底板 (歷史備用)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}fcitx.nix''${C_RESET}           : Fcitx5 + Rime 四葉草詞庫 + 小鶴雙拼 + 八股文語意模型"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}yazi.nix''${C_RESET}            : Yazi 檔案管理器 (Enter直連Helix, gD跳~/DOwn, Shift+Y複製)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}helix.nix''${C_RESET}           : Helix 編輯器 (Space+w存檔, Space+Space搜檔, Rust/Nix LSP)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}kitty.nix''${C_RESET}           : Kitty 終端機 (JetBrainsMono 18pt, 穿透Ctrl+Shift+C給Helix)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}rhys.nix''${C_RESET}            : 指揮中心百科與自救手冊指令"
      echo -e "      ''${C_GRAY}└──''${C_RESET} ''${C_WHITE}apps/''${C_RESET}                : 軟體安裝分流包 (apps-gui, apps-heavy, apps-sec)"

      echo -e "\n''${C_PURPLE}🏠 【用戶家目錄重要資料夾分布 (~/)】''${C_RESET}"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/.config/caelestia/shell.json''${C_RESET} : Caelestia Shell 設定檔 (禁用無用 OSD 亮度條)"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/.config/quickshell/''${C_RESET}          : QuickShell 自建與擴充 QML 腳本目錄"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/Pictures/Screenshots/''${C_RESET}        : 截圖自動存檔目錄"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/DOwn/''${C_RESET}                        : 常用下載目錄 (Yazi 中按 g D 直達)"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/.local/share/easyeffects/''${C_RESET}  : EasyEffects 卷積混響 (Convolver) 脈衝響應目錄"
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
    }

    # 2. 緊急搶救手冊 (rhys recover / rhys -r)
    show_recover() {
      show_header
      echo -e "\n''${C_RED}🚨 【緊急自救、斷網搶修與系統回滾總綱】''${C_RESET}"

      echo -e "\n''${C_PURPLE}📡 【情境一：dae 崩潰 / 配置錯誤，一秒切換中國國內直連】''${C_RESET}"
      echo -e "  ''${C_GRAY}原理：停用 eBPF 內核分流，重置 NetworkManager 路由，強制注入阿里/騰訊純淨 DNS。''${C_RESET}"
      echo -e "  ''${C_YELLOW}1. 掐死 dae 並阻斷自啟:''${C_RESET}"
      echo -e "     ''${C_GREEN}sudo systemctl stop dae && sudo systemctl disable --now dae''${C_RESET}"
      echo -e "  ''${C_YELLOW}2. 注入阿里/騰訊公共 DNS (直連國內骨幹網):''${C_RESET}"
      echo -e "     ''${C_GREEN}echo -e \"nameserver 223.5.5.5\nnameserver 119.29.29.29\" | sudo tee /etc/resolv.conf''${C_RESET}"
      echo -e "  ''${C_YELLOW}3. 重置網卡連線與驗證:''${C_RESET}"
      echo -e "     ''${C_GREEN}sudo systemctl restart NetworkManager; curl -I https://www.baidu.com''${C_RESET}"
      echo -e "  ''${C_YELLOW}4. dae 配置寫爛時一秒還原到 Git 上一個好版本:''${C_RESET}"
      echo -e "     ''${C_GREEN}git restore /etc/nixos/modules/dae-h3.nix''${C_RESET}"

      echo -e "\n''${C_PURPLE}📦 【情境二：完全斷網時，如何離線編譯 Nix 配置？】''${C_RESET}"
      echo -e "  ''${C_GRAY}原理：只要不修改 flake.nix inputs，利用本機 /nix/store 現有閉包即可 100% 離線構建！''${C_RESET}"
      echo -e "  ''${C_YELLOW}1. 純離線快速測試 (不連外網、不查遠端鏡像二進制):''${C_RESET}"
      echo -e "     ''${C_GREEN}sudo nixos-rebuild test --flake /etc/nixos --offline --option substitute false''${C_RESET}"
      echo -e "  ''${C_YELLOW}2. 純離線正式構建並生效:''${C_RESET}"
      echo -e "     ''${C_GREEN}sudo nixos-rebuild switch --flake /etc/nixos --offline --option substitute false''${C_RESET}"

      echo -e "\n''${C_PURPLE}🛠️  【情境三：磁碟爆滿 / Git 鎖死 / 衝突報錯救急】''${C_RESET}"
      echo -e "  ''${C_YELLOW}1. 磁碟 100% 寫入失敗 (緊急清空歷史世代垃圾釋放空間):''${C_RESET}"
      echo -e "     ''${C_GREEN}sudo nix-collect-garbage --delete-older-than 3d && sudo journalctl --vacuum-time=2d''${C_RESET}"
      echo -e "  ''${C_YELLOW}2. Home Manager 提示 '.backup already exists' 阻斷構建:''${C_RESET}"
      echo -e "     ''${C_GREEN}rm -f ~/.config/fuzzel/fuzzel.ini.backup (或刪除報錯路徑的 .backup)''${C_RESET}"
      echo -e "  ''${C_YELLOW}3. Git 被鎖死 (index.lock 衝突):''${C_RESET}"
      echo -e "     ''${C_GREEN}rm -f /etc/nixos/.git/index.lock''${C_RESET}"
      echo -e "  ''${C_YELLOW}4. Nix Store 資料校驗與修復 (斷電導致文件損壞):''${C_RESET}"
      echo -e "     ''${C_GREEN}sudo nix-store --verify --check-contents --repair''${C_RESET}"

      echo -e "\n''${C_PURPLE}⏳ 【情境四：世代回滾與開機終極救磚】''${C_RESET}"
      echo -e "  ''${C_YELLOW}1. 剛改完配置發現桌面崩潰（1秒熱回滾）:''${C_RESET}"
      echo -e "     ''${C_GREEN}nix-test -r''${C_RESET}                  (直接撤銷臨時配置)"
      echo -e "  ''${C_YELLOW}2. 命令行指定歷史黃金世代跳轉:''${C_RESET}"
      echo -e "     ''${C_GREEN}nix-save -l''${C_RESET}                  (看清歷史代數)"
      echo -e "     ''${C_GREEN}nix-save -r 196''${C_RESET}              (精準跳回第 196 號世代)"
      echo -e "  ''${C_YELLOW}3. 開機黑屏卡死（開機選單救磚）:''${C_RESET}"
      echo -e "     重開機在 systemd-boot 引導清單中，上下鍵選前一個成功啟動的代數直接回滾！"
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
    }

    # 3. 極客高階工具箱百科 (rhys tools / rhys -t)
    show_tools() {
      show_header
      echo -e "\n''${C_YELLOW}🛠️  【極客高階工具箱 · 實戰範例大百科】''${C_RESET}"

      echo -e "\n''${C_PURPLE}⏪ 【1. Git 實戰回滾與後悔藥 (時光倒流指南)】''${C_RESET}"
      echo -e "  ''${C_GRAY}• 工作區放棄修改 (還沒 git add):''${C_RESET}"
      echo -e "    ''${C_GREEN}git restore <檔案名>''${C_RESET}           # 放棄單檔修改 (如: git restore modules/pipewire.nix)"
      echo -e "    ''${C_GREEN}git restore .''${C_RESET}                  # 放棄當前目錄下所有未暫存的修改"
      echo -e "  ''${C_GRAY}• 撤出暫存區 (已經 git add，保留代碼):''${C_RESET}"
      echo -e "    ''${C_GREEN}git restore --staged <檔案名>''${C_RESET}"
      echo -e "  ''${C_GRAY}• 撤銷已 commit 的提交:''${C_RESET}"
      echo -e "    ''${C_GREEN}git reset --soft HEAD~1''${C_RESET}        # ⭐️ 溫和撤銷！保留寫好的代碼，變回未提交狀態"
      echo -e "    ''${C_GREEN}git reset --hard HEAD~1''${C_RESET}        # ⚠️ 徹底抹除最後一次 commit (代碼完全丟棄)"
      echo -e "  ''${C_GRAY}• 已經 push 到 GitHub 的優雅回滾 (不破壞遠端歷史):''${C_RESET}"
      echo -e "    ''${C_GREEN}git revert <commit-id>''${C_RESET}         # 生成一個完全抵消該提交的新 commit"
      echo -e "  ''${C_GRAY}• 終極後悔藥 (誤執行 reset --hard 救命草):''${C_RESET}"
      echo -e "    ''${C_GREEN}git reflog''${C_RESET}                     # 查看所有游標歷史黑匣子"
      echo -e "    ''${C_GREEN}git reset --hard HEAD@{2}''${C_RESET}      # 時光瞬間倒流回手滑前的狀態，代碼 100% 復活！"

      echo -e "\n''${C_PURPLE}📦 【2. FHS 異種二進制救急沙盒 (解決 No such file or directory)】''${C_RESET}"
      echo -e "  ''${C_GRAY}原理：NixOS 無標準 /lib64 與 /usr/bin，FHS 為外來二進制虛擬出傳統 Ubuntu/Arch 目錄層級。''${C_RESET}"
      echo -e "  ''${C_GRAY}• 萬能免配免編譯神器 (steam-run):''${C_RESET}"
      echo -e "    ''${C_GREEN}steam-run ./my-alien-binary''${C_RESET}    # 直接把任何網上下載的閉源程式/遊戲扔給它跑！"
      echo -e "  ''${C_GRAY}• 運行 AppImage 程式:''${C_RESET}"
      echo -e "    ''${C_GREEN}appimage-run ./app.AppImage''${C_RESET}"
      echo -e "  ''${C_GRAY}• 自定義 FHS 沙盒樣板 (寫在 Nix 配置中):''${C_RESET}"
      echo -e "    ''${C_CYAN}(pkgs.buildFHSEnv { name = \"fhs-env\"; targetPkgs = pkgs: [ pkgs.glibc pkgs.udev ]; runScript = \"bash\"; })''${C_RESET}"

      echo -e "\n''${C_PURPLE}🐚 【3. nix-shell (臨時借用工具，用完即焚零垃圾)】''${C_RESET}"
      echo -e "  ''${C_GRAY}• 臨時進入含指定工具的獨立終端 (退出後系統毫無殘留):''${C_RESET}"
      echo -e "    ''${C_GREEN}nix-shell -p python3 nodejs rustc''${C_RESET}"
      echo -e "  ''${C_GRAY}• 單次命令執行立刻銷毀 (極適合自動化腳本):''${C_RESET}"
      echo -e "    ''${C_GREEN}nix-shell -p yt-dlp --run \"yt-dlp https://youtu.be/xxx\"''${C_RESET}"
      echo -e "    ''${C_GREEN}nix-shell -p ffmpeg --run \"ffmpeg -i in.mp4 out.mp3\"''${C_RESET}"
      echo -e "  ''${C_GRAY}• 究極隔離純淨模式 (抹除主機原有所有 PATH 變數):''${C_RESET}"
      echo -e "    ''${C_GREEN}nix-shell --pure -p gcc gnumake''${C_RESET}"

      echo -e "\n''${C_PURPLE}⚡ 【4. nix run (現代 Flakes 點火發射器)】''${C_RESET}"
      echo -e "  ''${C_GRAY}• 直接從官方 nixpkgs 點火執行程式 (免安裝):''${C_RESET}"
      echo -e "    ''${C_GREEN}nix run nixpkgs#btop''${C_RESET}             # 臨時開啟 btop 監控"
      echo -e "    ''${C_GREEN}nix run nixpkgs#speedtest-cli''${C_RESET}    # 臨時測速"
      echo -e "  ''${C_GRAY}• 跨時空直接執行遠端 GitHub Flake 倉庫:''${C_RESET}"
      echo -e "    ''${C_GREEN}nix run github:caelestia-dots/shell''${C_RESET}"
      echo -e "  ''${C_GRAY}• ⚠️ 關鍵傳參技巧 (必須加雙橫線 -- 隔離參數):''${C_RESET}"
      echo -e "    ''${C_GREEN}nix run nixpkgs#ripgrep -- \"搜尋詞\" /etc/nixos/''${C_RESET}"
      echo -e "  ''${C_GRAY}• 概念對照:''${C_RESET} ''${C_YELLOW}nix shell''${C_RESET} 是開終端塞 PATH；''${C_YELLOW}nix run''${C_RESET} 是直接執行可執行檔！"

      echo -e "\n''${C_PURPLE}📖 【5. NixOS 核心手冊與選項離線大百科】''${C_RESET}"
      echo -e "  ''${C_GRAY}• 本地離線幾萬條系統配置字典 (按 / 鍵可直接搜尋):''${C_RESET}"
      echo -e "    ''${C_GREEN}man configuration.nix''${C_RESET}        # 查全系統每個選項的定義、型別與範例 (如: /pipewire)"
      echo -e "    ''${C_GREEN}man home-configuration.nix''${C_RESET}   # 查 Home Manager 所有用戶級設定字典"
      echo -e "  ''${C_GRAY}• 即時探測某個選項當前生效值與定義來源:''${C_RESET}"
      echo -e "    ''${C_GREEN}nixos-option services.pipewire''${C_RESET}"
      echo -e "    ''${C_GREEN}nixos-option powerManagement.cpuFreqGovernor''${C_RESET}"
      echo -e "  ''${C_GRAY}• \"缺少命令該裝什麼包？\" 終極反查神器:''${C_RESET}"
      echo -e "    ''${C_GREEN}nix-locate bin/killall''${C_RESET}        # 毫秒級告訴你它屬於 psmisc 包"
      echo -e "  ''${C_GRAY}• Nix 語言互動式求值終端 (像 Python 一樣查對象):''${C_RESET}"
      echo -e "    ''${C_GREEN}nix repl --file \"<nixpkgs>\"''${C_RESET}   # 輸入 pkgs.hello.version 查版本，:q 退出"
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
    }

    # 4. 預設總覽手冊 (rhys / rhys -h)
    show_summary() {
      show_header
      echo -e "\n''${C_PURPLE}❄️  【NixOS 核心指令】''${C_RESET}"
      echo -e "  ''${C_GREEN}nix-test''${C_RESET}                 : 測試編譯當前配置 (不產生世代垃圾)"
      echo -e "  ''${C_GREEN}nix-test -r''${C_RESET}              : ⭐️ 測試失敗時 1 秒熱回滾！"
      echo -e "  ''${C_GREEN}nix-save''${C_RESET}                 : 正式構建世代、同步 GitHub 並記錄世代"
      echo -e "  ''${C_GREEN}nix-save -l / -r [N]''${C_RESET}     : 查詢世代清單 / 回滾到指定代數 (如: nix-save -r 196)"
      echo -e "  ''${C_GREEN}nix-load''${C_RESET}                 : 從遠端 GitHub 強制拉取最新配置並重構"

      echo -e "\n''${C_BLUE}🖥️  【Caelestia Shell 快捷操作】''${C_RESET}"
      echo -e "  ''${C_YELLOW}Super + 空格''${C_RESET}            : 呼出 / 收起 應用程式啟動器 (App Launcher)"
      echo -e "  ''${C_YELLOW}Super + D / C''${C_RESET}           : 呼出 / 收起 控制中心 (Dashboard)"
      echo -e "  ''${C_YELLOW}Super + N''${C_RESET}               : 呼出 / 收起 側邊欄通知中心 (Sidebar)"
      echo -e "  ''${C_YELLOW}Super + ESC''${C_RESET}             : 呼出 電源 / 鎖屏 / 重啟面板 (Session)"
      echo -e "  ''${C_GREEN}caelestia wallpaper set <圖>''${C_RESET}: 根據壁紙色彩即時提取 Material 莫蘭迪主題色"
      echo -e "  ''${C_GREEN}systemctl --user restart caelestia-shell''${C_RESET}: 重啟 Caelestia 桌面守護進程"

      echo -e "\n''${C_YELLOW}🎧 【ROG R5E SupremeFX 發燒音訊調控】''${C_RESET}"
      echo -e "  ''${C_GREEN}pw-top''${C_RESET}                  : 即時查看 Quantum 256 @ 5.3ms 錄音棚極限耳返延遲"
      echo -e "  ''${C_GREEN}alsamixer''${C_RESET}                : F6 選 HDA Intel PCH，確認 PCM 為 100 (0dB 滿位深直通)"
      echo -e "  ''${C_GRAY}├─ 綠孔 (Front/Line Out)''${C_RESET}: 耳機/主音響 (直通 TI LM4562 旗艦運放)"
      echo -e "  ''${C_GRAY}├─ 藍孔 (Line In)''${C_RESET}       : 錄音筆/電容麥克風 (純淨模擬直通，無二次放大與直流倒灌)"
      echo -e "  ''${C_GRAY}└─ 黑孔 (Rear Out)''${C_RESET}      : 可設為 4.0 鏡像，同時直連外部功放"

      echo -e "\n''${C_CYAN}📁 【檔案、編輯器與剪貼簿 (Yazi / Helix)】''${C_RESET}"
      echo -e "  ''${C_GREEN}y''${C_RESET} 或 ''${C_GREEN}yy''${C_RESET}                   : 啟動 Yazi (退出時終端自動跳轉到所在目錄)"
      echo -e "  ''${C_YELLOW}Super + E''${C_RESET}               : 螢幕正中央彈出置中懸浮 Yazi"
      echo -e "  ''${C_GRAY}├─ Yazi 內快捷鍵:''${C_RESET}       ''${C_YELLOW}g D''${C_RESET} 跳 ~/DOwn | ''${C_YELLOW}g n''${C_RESET} 跳 /etc/nixos | ''${C_YELLOW}g m''${C_RESET} 跳 modules"
      echo -e "  ''${C_GRAY}└─ Yazi 內複製:''${C_RESET}         選中檔案按 ''${C_YELLOW}Shift + Y''${C_RESET} 複製檔案實體進剪貼簿"
      echo -e "  ''${C_GREEN}hx <檔案>''${C_RESET}                : Helix 編輯器 (Space+Space 搜檔 | Space+w 存檔)"

      echo -e "\n''${C_GREEN}🌐 【網路、代理與輸入法】''${C_RESET}"
      echo -e "  ''${C_GREEN}sudo systemctl restart dae''${C_RESET}: 重啟 dae 代理，強制重新測速並清空 DNS 快取"
      echo -e "  ''${C_GREEN}journalctl -u dae -f''${C_RESET}      : 即時查看 dae eBPF 內核分流日誌"
      echo -e "  ''${C_YELLOW}Win + Space''${C_RESET}             : 切換 英文 / 中州韻 (Rime)"
      echo -e "\n''${C_GRAY}💡 進階指令:''${C_RESET}"
      echo -e "  ''${C_CYAN}rhys tools   (rhys -t)''${C_RESET} : 查看 Git回滾、FHS沙盒、nix-shell/run實例、離線手冊大百科"
      echo -e "  ''${C_CYAN}rhys recover (rhys -r)''${C_RESET} : 查看斷網救急、離線編譯、磁碟救援手冊"
      echo -e "  ''${C_CYAN}rhys files   (rhys -f)''${C_RESET} : 查看全系統模組目錄架構地圖"
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
    }

    # 參數分流
    case "$1" in
      files|-f|--files)
        show_files
        ;;
      recover|-r|--recover|rescue)
        show_recover
        ;;
      tools|-t|--tools|advanced|-a|--advanced)
        show_tools
        ;;
      help|-h|--help|*)
        show_summary
        ;;
    esac
  '';
in
{
  home.packages = [
    rhysCommand
  ];

  # ⭐️ 給 Fish 加上 rhys 的子命令 Tab 自動補全
  xdg.configFile."fish/completions/rhys.fish".text = ''
    complete -c rhys -s f -l files -d "查看全系統核心與模組檔案架構分布地圖"
    complete -c rhys -s r -l recover -d "查看離線編譯、dae斷網救急與系統回滾手冊"
    complete -c rhys -s t -l tools -d "查看 Git回滾、FHS沙盒、nix-shell/run實戰與離線手冊百科"
    complete -c rhys -s h -l help -d "顯示常用指令、Caelestia快捷鍵與音訊總覽"
  '';
}
