{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # 1. 核心引導橋樑
    extraConfig = ''
      local home = os.getenv("HOME")
      package.path = home .. "/.config/MYHYprLUa/?.lua;" .. package.path
      
      local function safe_load(m) 
        local ok, err = pcall(require, m) 
        if not ok then hl.exec_cmd("notify-send 'Error' 'Fail to load "..m.."'") end 
      end

      safe_load("default")
    '';
  };

  

  # 2. default.lua 入口
  xdg.configFile."MYHYprLUa/default.lua".text = ''
    -- 基礎操作
    -- 定義全域核心變數（供所有子模組共用）
    mainMod     = "SUPER"
    terminal    = "kitty"
    fileManager = "nemo"
    menu        = "caelestia shell drawers toggle launcher"    
    hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
    hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
    hl.bind(mainMod .. " + SHIFT + DELETE", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
    hl.bind(mainMod .. " + SHIFT + CTRL + ALT + DELETE", hl.dsp.exec_cmd("hyprctl reload"))
    require("AUTOSTART")
    require("bindings")
    require("MONITORS")
    require("ENVIRONMENT")
    require("LOOKANDFEEL")
    require("MISC")
    require("INPUT")
    require("WINDOWSANDWORKSPACES")
    require("window_rules")
  '';

  # =======================================================
  # 1. 視窗規則模組 (⭐️ 浮動優先 · 白名單平鋪架構)
  # =======================================================
  xdg.configFile."MYHYprLUa/window_rules.lua".text = ''
    -- 0. 底層防禦
    hl.window_rule({ name = "suppress_maximize", match = { class = ".*" }, suppress_event = "maximize" })
    hl.window_rule({ name = "fix_xwayland_drags", match = { class = "^$", title = "^$", xwayland = true }, no_focus = true })

    -- =========================================================================
    -- 👑 【核心基石】：全系統所有視窗，預設全部浮動！居中！
    -- （任何流氓彈窗、PicoKey、無名窗口一律被壓制在浮動層，絕不破壞螢幕！）
    -- =========================================================================
    hl.window_rule({ 
      name = "default_float_all", 
      match = { class = ".*" }, 
      float = true, 
      center = true,
      size = "50% 100%" -- 預設給一個舒適的黃金比例尺寸
    })

    -- =========================================================================
    -- ⭐️ 【平鋪白名單 (Tile Whitelist)】：只有這些正經生產力工具，才准平鋪分屏！
    -- =========================================================================
    
    -- 1. 主瀏覽器：只有「真正的主頁面」才准平鋪，所有外掛/帳密/USB彈窗自然享受預設浮動！
    hl.window_rule({ 
      name = "tile_browser_main", 
      match = { 
        class = "^(google-chrome|com\\.google\\.Chrome|chromium-browser|firefox)$",
        -- 核心過濾：標題必須有網頁標籤（防止把無名彈窗也一起平鋪了）
        title = "^(.* - Google Chrome|.* - Chromium|.* — Mozilla Firefox)$" 
      }, 
      tile = true,
      workspace = "1"
    })

    -- 2. 程式碼編輯器 (VSCode / Codium) 必須平鋪
    hl.window_rule({ 
      name = "tile_code_editors", 
      match = { class = "^(codium|vscodium|VSCodium|code)$" }, 
      tile = true 
    })

    -- 3. REAPER 音訊宿主的主工程視窗（主軌道平鋪，但它的 VST 外掛享受預設浮動！）
    hl.window_rule({ 
      name = "tile_reaper_main", 
      match = { class = "^(REAPER)$", title = "^REAPER v.*$" }, 
      tile = true 
    })

    -- 4. 終端機：如果你希望某個主力終端平鋪，可以在這裡放行（如果不寫，Kitty 就預設浮動）
    -- hl.window_rule({ name = "tile_kitty", match = { class = "^(kitty)$" }, tile = true })

    -- =========================================================================
    -- 🎯 【微調修正】：針對特定浮動視窗的尺寸/位置自訂
    -- =========================================================================
    
    -- 認證/密碼/硬體 Key (精巧小卡片，貼右上角或置中)
    hl.window_rule({ 
      name = "auth_and_keys", 
      match = { class = "^(fido2-manage|pinentry-.*|gcr-prompter|.*polkit.*|yad|zenity)$" }, 
      size = "420 280", 
      center = true 
    })

    -- 瀏覽器畫中畫 (右下角釘子戶)
    hl.window_rule({ 
      name = "browser_pip", 
      match = { title = "^(Picture-in-Picture|畫中畫|子母畫面)$" }, 
      pin = true, 
      keep_aspect_ratio = true, 
      size = "26% 26%", 
      move = "73% 72%" 
    })

    -- 4 號發燒音訊工作區：左右 50% 對開
    hl.window_rule({ name = "音量控制", match = { class = "org.pulseaudio.pavucontrol" }, size = "99% 99%", center = true , move = "0 0" })
    hl.window_rule({ name = "qpwgraph_ws4", match = { class = "org.rncbc.qpwgraph" }, workspace = "4 silent", size = "50% 100%", move = "0 0" })
    hl.window_rule({ name = "easyeffects_ws4", match = { class = "com.github.wwmm.easyeffects" }, workspace = "4 silent", size = "50% 100%", move = "50% 0" })

    -- 社交軟體靜音分流
    hl.window_rule({ name = "discord_ws3", match = { class = "discord" }, workspace = "3 silent" })
    hl.window_rule({ name = "spotify_ws3", match = { class = "^(spotify|Spotify)$" }, workspace = "3 silent" })

    -- =========================================================================
    -- 🧠 4. 智能記憶引擎：全自動讀取用戶隨手標記的「永久浮動黑名單」
    -- =========================================================================
    --local memory_file = os.getenv("HOME") .. "/.config/hypr/learned_floats.txt"
    --local f = io.open(memory_file, "r")
    --if f then
    --  local mem_idx = 100
    --  for line in f:lines() do
    --    -- 去除首尾空格
    --    line = line:match("^%s*(.-)%s*$")
    --    if line ~= "" and not line:match("^#") then
    --      hl.window_rule({
    --        name = "user_remembered_" .. mem_idx,
    --        match = { class = "^(" .. line .. ")$" },
    --        float = true,
    --        center = true,
    --        size = "65% 70%" -- 預設給優雅黃金比例
    --      })
    --      mem_idx = mem_idx + 1
    --    end
    --  end
    --  f:close()
    --end

  '';

  # =======================================================
  # 2. 快捷鍵模組
  # =======================================================
  xdg.configFile."MYHYprLUa/bindings.lua".text = ''
    -- =======================================================
    -- ⭐️ 官方原生：Alt + Tab 切換視窗並置頂層級 (誰在前誰在後)
    -- =======================================================
    
    -- Super + X：呼出網格/字母標籤定位，打字即可瞬間點擊目標
    -- hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("wl-kbptr"))

    -- Super + C：二分精確逼近模式（逐級縮小區域精確漫遊）
    -- hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("wl-kbptr --mode bisect"))

    -- 1. Alt + Tab：順向切換視窗，並將該視窗翻到最頂層
    hl.bind("ALT + Tab", function()
      hl.dispatch(hl.dsp.window.cycle_next())
      hl.dispatch(hl.dsp.window.bring_to_top())
    end)

    -- 2. Alt + Shift + Tab：反向切換視窗，並將該視窗翻到最頂層
    hl.bind("ALT + SHIFT + Tab", function()
      hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
      hl.dispatch(hl.dsp.window.bring_to_top())
    end)

    -- ⭐️ 2. Ctrl + Super + W：隨機抽取一張 2K 高畫質桌布（8大轉場特效全隨機！）
    hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("wall-random"))
    -- ⭐️ 2. Ctrl + Super + W：隨機抽取一張 2K 高畫質桌布（8大轉場特效全隨機！）
    hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("wall-video"))

    -- 綁定 Ctrl + Shift + Super + A 執行繁簡轉換並複製檔案
    hl.bind(mainMod .. " + SHIFT + CTRL + A", hl.dsp.exec_cmd("fish -c scc"))
    hl.bind(mainMod .. " + SHIFT + CTRL + Z", hl.dsp.exec_cmd("fish -c tcc"))

    -- 錄影快捷鍵
    hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("record-screen area"))
    hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("record-screen fullscreen"))
    
    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
    --hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
    hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
    hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

    hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + ALT + F", hl.dsp.exec_cmd("hypr-remember-float"))
    --hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill -SIGUSR1 .waybar-wrapped || pkill -SIGUSR1 waybar"))
    hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"))
    hl.bind(mainMod .. " + SHIFT + CTRL + S", hl.dsp.exec_cmd("trans-gui"))

    -- 方向導航
    hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
    hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
    hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
    hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
    -- 窗口摆放
    --hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
    --hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
    --hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
    --hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

    -- =======================================================
    -- ⭐️ 專業截圖矩陣（截選單、全螢幕、區域拉框全搞定）
    -- =======================================================

    -- 1. ⭐️ 區域定格截圖（真正的一鍵定格拉框，絕不誤解凍）：Super + Ctrl + S
    hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("hyprshot -m region --freeze -o ~/Pictures/Screenshots"))

    -- 2. 全螢幕定格秒截：Super + Print
    hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m output --freeze -o ~/Pictures/Screenshots"))

    -- 3. 當前單一視窗截圖（可選）：Super + Alt + S
    hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd("hyprshot -m window --freeze -o ~/Pictures/Screenshots"))

    -- 工作區切換
    for i = 1, 10 do
        local key = i % 10
        hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
        hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
    end

    -- 暫存空間 Magic
    hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

    -- 滾輪切換工作區
    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    -- 滑鼠拖曳與縮放
    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- 筆電多媒體鍵
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
    hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
    hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

    hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
  '';

  xdg.configFile."MYHYprLUa/MONITORS.lua".text = '''';

  # =======================================================
  # 5. 自啟動模組 (開機視角牢牢鎖定 Workspace 1)
  # =======================================================
  xdg.configFile."MYHYprLUa/AUTOSTART.lua".text = ''
   hl.on("hyprland.start", function ()
      hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
      hl.exec_cmd("fcitx5 -d")
      hl.exec_cmd("wall-random")
      hl.exec_cmd("google-chrome")
      hl.exec_cmd("qpwgraph")
      hl.exec_cmd("discord")
      
      -- ⭐️ 核心保險：等背景程式就位後，把視角強制拉回 1 號工作區！
      hl.exec_cmd("sleep 0.5 && hyprctl dispatch workspace 1")
    end)
  '';

  xdg.configFile."MYHYprLUa/ENVIRONMENT.lua".text = ''
    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")
  '';

  # =======================================================
  # 7. 外觀與高質感調光模組 (LOOKANDFEEL.lua)
  #    ⭐️ 徹底刪除重複定義，解除暗淡，開啟高級質感
  # =======================================================
  xdg.configFile."MYHYprLUa/LOOKANDFEEL.lua".text = ''
    hl.config({
        cursor = {
        no_hardware_cursors = false,    -- ⭐️ 強制開啟顯卡硬體游標
        use_cpu_buffer = false,         -- ⭐️ 嚴禁使用 CPU 記憶體畫滑鼠！由 GPU 顯存直接輸出
        no_break_fs_vrr = true,
        min_refresh_rate = 60,          -- 最低鎖定 60 幀
        },
        general = {
            gaps_in  = 5,
            gaps_out = 16,
            border_size = 2,

            col = {
                -- ⭐️ 當前視窗：賽博青藍到極光紫的流光邊框
                active_border   = { colors = {"rgba(33ccffee)", "rgba(bd93f9ee)"}, angle = 45 },
                -- ⭐️ 非當前視窗：深邃黑曜石邊框，低調優雅
                inactive_border = "rgba(1e1e2eaa)",
            },

            resize_on_border = false,
            -- ⭐️ 開啟極致響應（允許遊戲或全螢幕無延遲直通，消除微幅卡頓）
            allow_tearing = true,
            layout = "dwindle",
        },

        -- 找到第 166 行左右的 decoration 配置塊：
        decoration = {
            rounding       = 16,    -- 👈 建议从 12 提升至 14~16（苹果标准大圆角）
            rounding_power = 4.0,   -- 👈 ⭐️ 核心关键！把 2 改为 4.0（正式激活 Apple G2 Squircle 超椭圆曲线！）

            -- 视窗 100% 清澈透亮
            active_opacity   = 1.0,
            inactive_opacity = 1.0,

            dim_inactive = false,
            dim_strength = 0.0,

            -- 漫射环境光阴影
            shadow = {
                enabled      = true,
                range        = 25,  -- 稍微增大弥散范围
                render_power = 4,   -- 提升阴影层次
                color        = 0x44000000,
            },

            -- 3 遍极深 Kawase 磨砂毛玻璃
            blur = {
                enabled   = true,
                size      = 7,
                passes    = 3,
                new_optimizations = true,
                ignore_opacity    = true,
                vibrancy          = 0.25,
            },
        },

        animations = {
            enabled = true,
        },
    })

    -- 絲滑貝茲曲線
    hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
    hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
    hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
    hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
    hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
    hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

    hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
    hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
    hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
    hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
    hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
    hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
    hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
    hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
    hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
    hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
    hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
    hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
    hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
    hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
    hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

    hl.config({
        dwindle = {
            preserve_split = true,
        },
        master = {
            new_status = "master",
        },
        scrolling = {
            fullscreen_on_one_column = true,
        },
    })
  '';

  xdg.configFile."MYHYprLUa/MISC.lua".text = ''
    hl.config({
      misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        focus_on_activate       = false, -- ⭐️ 禁止軟體在後台啟動時搶奪焦點
      },
    })
  '';

  xdg.configFile."MYHYprLUa/INPUT.lua".text = ''
    hl.config({
      input = {
        accel_profile = "flat", -- 絕對直線，無軟體加速
        kb_layout  = "us",
        -- 0：必須點擊滑鼠 才能激活視窗（點擊激活，之前你的配置裡設成了 0）。
        -- 1（最常用 ⭐️）：滑鼠移到哪裡，焦點就自動切換到哪個視窗（懸停即激活）。
        -- 2：分離模式（鍵盤焦點與滑鼠焦點分離，點擊才鎖定鍵盤輸入）。
        -- 3：完全點擊模式。
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
      },
    })

    hl.gesture({
      fingers = 3,
      direction = "horizontal",
      action = "workspace"
    })
  '';

  xdg.configFile."MYHYprLUa/WINDOWSANDWORKSPACES.lua".text = ''
    hl.window_rule({
      name  = "suppress-maximize-events",
      match = { class = ".*" },
      suppress_event = "maximize",
    })

    hl.window_rule({
      name  = "fix-xwayland-drags",
      match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
      },
      no_focus = true,
    })
  '';     
}
