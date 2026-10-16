{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # --- 1. 漏洞利用平台與全套框架 ---
    metasploit                # 全球最廣泛使用的滲透測試與漏洞利用框架
    exploitdb                 # 官方 Exploit-DB 離線安全漏洞庫搜尋工具 (searchsploit)
    aflplusplus               # AFL++ 現代頂級模糊測試 (Fuzzing) 工具

    # --- 2. 系統安全審計、底層跟蹤與逆向工程 ---
    lynis                     # Linux 系統深度合規性與安全性自動審計工具
    ltrace                    # 攔截並記錄進程動態呼叫的共享庫函數
    checksec                  # 檢查二進位檔案編譯安全屬性 (RELRO, Canaries, NX, PIE)
    gdb                       # GNU 原生底層除錯器
    radare2                   # 極度強大的開源逆向工程框架與十六進位分析器
    scanmem                   # 進程記憶體即時搜尋與分析修改器
    perf                      # Linux 核心級別效能探針與事件採集工具
    bpftrace                  # 基於 Linux eBPF 的高級動態追蹤語言

    # --- 3. 密碼破譯與字典生成工具 ---
    cewl                      # 爬取指定網頁詞彙自動生成客製化爆破字典
    crunch                    # 強大的排列組合字元集字典生成器
    hydra                     # 極速多執行緒網路登入協定暴力破解工具
    medusa                    # 模組化、並行的網路暴力認證審查器

    # --- 4. Web 滲透、路徑爆破與指紋識別 ---
    httpx                     # 高併發 HTTP 探測與技術棧指紋識別工具
    whatweb                   # 辨識網站 CMS、服務端架構與腳本類型的指紋掃描器
    wpscan                    # 專門針對 WordPress 網站黑盒安全漏洞掃描器
    ffuf                      # 極速現代 Go 撰寫的 Web 路徑與參數 Fuzzing 工具
    nikto                     # 經典 Web 伺服器存在已知風險與危險檔案掃描器
    sqlmap                    # 自動化 SQL 注入偵測與資料庫權限接管神兵
    oha                       # 終端 HTTP 請求壓測與回應時間分佈可視化工具

    # --- 5. 網路流量嗅探、劫持與中間人攻擊 (MITM) ---
    tcpdump                   # 原始網路封包抓取與過濾器
    libpcap                   # 封包捕獲系統底層核心庫
    ngrep                     # 配合正則表達式網路封包 Grep 搜尋器
    dsniff                    # 專門用於監聽網路明文口令與敏感資訊工具套裝
    bettercap                 # 現代模組化中間人攻擊 (MITM) 與網路欺騙框架
    mitmproxy                 # 具備 Web 介面與 Python 腳本擴展的互動式 HTTP/HTTPS 攔截代理
    suricata                  # 高性能開源網路威脅檢測與入侵防禦系統 (IDS/IPS)

    # --- 6. 網路掃描、主機探測與原始 Socket 構造 ---
    nmap                      # 網路探測與主機埠安全審計標準工具
    masscan                   # 號稱 6 分鐘掃描全網的最快非同步 TCP 埠掃描器
    zmap                      # 單一資料包網路掃描器 (全網研究利器)
    arping                    # 透過 ARP 請求發現並探測局域網物理主機
    fping                     # 高效能批量主機在線 Ping 探測工具
    hping                     # 構造自訂 TCP/IP 封包、繞過防火牆規則檢測工具
    traceroute                # 經典路由路徑逐跳檢測工具
    socat                     # 雙向資料串流轉發與端口重定向多功能工具
    netcat                    # 經典網路連線瑞士軍刀 (nc)

    # --- 7. 無線網路安全與專用攻擊套件 ---
    wifite2                   # 自動化無線 Wi-Fi (WPA/WPA2/WPS) 滲透測試工具
    thc-ipv6                  # 專門用於攻擊、測試與診斷 IPv6 協定棧安全缺陷的工具套件
    torque                    # 批量作業與分散式運算管理支援工具

    # --- 8. 安全通訊與終端 IRC ---
    weechat                   # 模組化終端輕量 IRC / 矩陣聊天客戶端
    irssi                     # 經典文本終端 IRC 客戶端
    hexchat                   # GTK 圖形化多伺服器 IRC 客戶端
    yt-dlp                    # 全網音視頻取證與無損提取工具
  ];
}
