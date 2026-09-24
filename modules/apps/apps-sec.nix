# /etc/nixos/modules/apps/apps-sec.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 1. 開發編譯套件
    cargo rustc devbox glib
    gcc gnumake libtool jq
    luajit wev socat opencc ffmpeg gitoxide

    # 2. 取證與底層除錯工具
    lynis ltrace strace checksec gdb radare2

    # 3. 字典與暴破
    cewl crunch hydra medusa

    # 4. Web 滲透與掃描
    httpx whatweb wpscan ffuf nikto sqlmap oha

    # 5. 網路流量與封包分析 (IDS/嗅探)
    suricata mitmproxy ngrep dsniff bettercap tcpdump traceroute

    # 6. 網路探測與主機掃描
    arping hping fping socat netcat zmap masscan nmap

    # 7. 逆向 与 CPU探针
    perf bpftrace
  ];
}
