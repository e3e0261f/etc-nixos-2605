# /etc/nixos/modules/apps/apps-sec.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 1. 開發編譯套件
    cargo rustc devbox glib
    gcc gnumake libtool jq libpcap  
    luajit wev socat opencc ffmpeg gitoxide

    # 2. 取證與底層除錯工具
    lynis ltrace strace checksec gdb radare2

    # 3. 字典與暴破
    cewl crunch hydra medusa

    # 4. Web 滲透與掃描
    httpx whatweb wpscan ffuf nikto sqlmap oha masscan zmap nmap  

    # 5. 網路流量與封包分析 (IDS/嗅探)
    suricata mitmproxy ngrep dsniff bettercap tcpdump traceroute

    # 6. 網路探測與主機掃描
    arping hping fping socat netcat zmap masscan nmap

    # 7. 逆向 与 CPU探针
    perf bpftrace

    # 8. attack kitool
    thc-ipv6 yt-dlp wifite2 torque openssl openssh exploitdb
    weechat  # 强大的终端文本 IRC 客户端
    irssi  # 如果你更喜欢传统的终端客户端，可以选这个
    hexchat # 如果你有桌面环境，喜欢图形界面，可以选这个
  ];
}
