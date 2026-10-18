# /etc/nixos/modules/dae-h3.nix (或 dae.nix)
# echo '1' > /proc/sys/net/ipv6/conf/<ifname|all|default>/disable_ipv6
# sysctl net.ipv6.conf.<ifname|all|default>.disable_ipv6=1
{ pkgs, inputs, ... }:

let
  my-dae-assets = pkgs.stdenv.mkDerivation {
    name = "my-dae-assets";
    src = inputs.my-rules; 
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/v2ray
      cp $src/geoip.dat $out/share/v2ray/geoip.dat
      cp $src/geosite.dat $out/share/v2ray/geosite.dat
    '';
  };
in
{
  # 开启自定义地址排序配置
  networking.getaddrinfo.enable = true;

  # 通过调整 precedence（优先级）表，让系统内核在解析域名时
  # 优先选择 IPv4-mapped  地址（即优先走 IPv4），而不是盲目冲向 IPv6
  networking.getaddrinfo.precedence = {
    "::1/128" = 50;
    "::/0" = 40;
    "2002::/16" = 30;
    "::/96" = 20;
    "::ffff:0:0/96" = 100; # 🌟 核心：把 IPv4 的优先级设为 100（最高），压过原本的 IPv6
  };

  services.dae = {
    enable = true;
    assets = [ my-dae-assets ];

    config = ''
      global {
          allow_insecure: false
          so_mark_from_dae: 0
          dial_mode: domain
          log_level: info
          tproxy_port: 7890
          # Enable fast redirect for local TCP connections. There is a known kernel issue that breaks certain clients/proxies, such as nadoo/glider. Users may enable this experimental option at their own risks.
          enable_local_tcp_fast_redirect: true
          # The LAN interface to bind. Use it if you want to proxy LAN.
          # Multiple interfaces split by ",".
          lan_interface: wlp8s0, auto
          # The WAN interface to bind. Use it if you want to proxy localhost.
          # Multiple interfaces split by ",". Use "auto" to auto detect.
          wan_interface: auto
          # Automatically configure Linux kernel parameters like ip_forward and send_redirects. Check out
          # https://github.com/daeuniverse/dae/blob/main/docs/en/user-guide/kernel-parameters.md to see what will dae do.
          auto_config_kernel_parameter: true
          # 尝试把 DNS 监听绑定到本地回环地址
          # dns_listen: 127.0.0.1:53 
          tproxy_port_protect: true
          # This DNS will be used to check UDP connectivity of nodes. And if dns_upstream below contains tcp, it also be used to check
          # TCP DNS connectivity of nodes.
          # First is URL, others are IP addresses if given.
          # This DNS should have both IPv4 and IPv6 if you have double stack in local.
          udp_check_dns: 'dns.google:53'
          # udp_check_dns: 'dns.google:53,8.8.8.8,2001:4860:4860::8888'
          # The HTTP request method to `tcp_check_url`. Use 'HEAD' by default because some server implementations bypass
          # accounting for this kind of traffic.
          tcp_check_http_method: HEAD
          # 🌟【核心降級修復】縮短健康度探測間隔與超時時間
          # 配置刷新时间
          check_interval: 610s
          # 探測超時時間
          check_tolerance: 5s
          # Timeout to waiting for first data sending for sniffing. It is always 0 if dial_mode is ip. Set it higher is useful
          # in high latency LAN network.
          sniffing_timeout: 100ms
          # TLS implementation. tls is to use Go's crypto/tls. utls is to use uTLS, which can imitate browser's Client Hello.
          tls_implementation: utls
          # The Client Hello ID for uTLS to imitate. This takes effect only if tls_implementation is utls.
          # See more: https://github.com/daeuniverse/dae/blob/331fa23c16/component/outbound/transport/tls/utls.go#L17
          utls_imitate: chrome_auto
          # Multipath TCP (MPTCP) support. If is true, dae will try to use MPTCP to connect all nodes, but it will only take
          # effects when the node supports MPTCP. It can use for load balance and failover to multiple interfaces and IPs.
          mptcp: false
          # The maximum bandwidth for accessing the Internet. It is useful for some specific protocols (e.g., Hysteria2),
          # which will perform better with bandwith information provided. The unit can be b, kb, mb, gb, tb or bytes per second.
          # supported formats: https://v2.hysteria.network/docs/advanced/Full-Client-Config/#bandwidth
          bandwidth_max_tx: '50 mbps' # uplink, or '200 m' or '200 mb' or '200 mbps' or 25000000(which is 200/8*1000*1000)
          bandwidth_max_rx: '1 gbps' # downlink, or '1 g' or '1 gb' or '1 gbps' or 125000000(which is 1000/8*1000*1000)
      }

      subscription {
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY'
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=4'
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=3'
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=2'
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=1'
          my_sub: 'https://link.rockey-repo.org/link/CEYCDf96zE5dU6gY'
          my_sub: 'https://api0.bigmelook.com/BigME/Subscription/api/v1/client/subscribe?token=d2ecd2c553222f8b8df5347c8224976b'
      }

      # =======================================================
      # ⭐️ 穩定極速 DNS 解析
      # =======================================================
      #
      dns {
        upstream {
          googledns: 'tcp+udp://8.8.8.8:53'
          alidns: 'udp://223.5.5.5:53'
          ali_h3: 'h3://223.5.5.5:443/dns-query'
          # Cloudflare: 'tcp+udp://1.1.1.1:53'
          # Cloudflare: 'tcp+udp://1.0.0.1:53'
          # Cloudflare: 'https://1.1.1.1/dns-query'
          # Cloudflare: 'h3://dns.cloudflare.com/dns-query'
          # Cloudflare: 'h3://1.1.1.1/dns-query'
        }
        routing {
          request {
            qtype(https) -> reject
            qtype(aaaa) -> reject

            # 2. ✨【您的指定】所有 Google 網域強制走自己的 googledns (8.8.8.8)
            # !qname(geosite:cn) && qname(geosite:google) -> googledns
            !qname(geosite:cn)  -> googledns

            # 3. ✨【您的指定】除了 Google 以外的其他國外網域走Cloudflare DoH3
            # !qname(geosite:cn) -> Cloudflare

            fallback: ali_h3
          }
          response {
            # 信任我們啟用的安全上游
            upstream(googledns) -> accept
            # upstream(Cloudflare) -> accept
            upstream(ali_h3) -> accept
            ip(geoip:private) && !qname(geosite:cn) -> googledns
            # ip(geoip:private) && !qname(geosite:cn) -> Cloudflare
            fallback: accept
          }
        }
      }
      # =======================================================
      # ⭐️ 核心節點池
      # =======================================================
      group { # 在这里替换你想要的策略，如 random, min, fixed(0), min_avg10
          for1 {
              policy: min_avg10
              filter: subtag(my_sub) && !name(regex: '4倍|6倍|HK|广州|剩余|到期|3x|客服|支持AI')
          }

          for4 {
              policy: min_moving_avg
              # policy: min_avg10
              # policy: random
              filter: subtag(my_sub) && name(regex: '4倍') && !name(regex: 'HK|广州|剩余|到期|3x|客服|支持AI')
          }
          
          for46 {
              policy: min_moving_avg
              # policy: min_avg10
              # policy: random
              filter: subtag(my_sub) && name(regex: 'I|REALITY') && !name(regex: 'HK|广州|剩余|到期|3x|客服|支持AI')
          }

          for146 {
              policy: min_moving_avg
              # policy: min_avg10
              filter: subtag(my_sub) && !name(regex: 'HK|广州|剩余|到期|3x|客服|支持AI')
          }

          google_ai {
              policy: min_moving_avg
              # policy: random
              # policy: min_avg10
              filter: subtag(my_sub)  && name(regex: '1|4|6|I') && !name(regex: 'HK|广州|剩余|到期|3x|客服|支持AI')
          }

      }

      # =======================================================
      # ⭐️ 路由分流規則（嚴格從上到下匹配）
      # =======================================================
      routing {
          # dport(443) && l4proto(udp) -> block
          # ipversion(6) -> block
          # ⭐️【第 0 級最高優先】：系統底層、遊戲與核心直連
          pname(Albion-Online, albion-online) -> direct(must)
          pname(cloudflared) -> direct(must)
          domain(keyword: "argotunnel.com") -> direct
          domain(keyword: "cloudflare.com") -> direct
          domain(suffix: albiononline.com) -> direct(must)
          pname(gix, Counter-Strike) -> direct(must)
          pname(Team, tf_linux64) -> direct
          # wow
          domain(suffix: battle.net) -> direct
          domain(keyword: blizzard, "battle.net") -> direct
          # pname(Battle.net.exe, Agent.exe, Wow.exe) -> direct
          # pname(wine, wineserver, winedevice.exe) -> direct
          
          # 2. Steam 流量精準分流
          # 下載伺服器域名字尾匹配（直連）
          domain(suffix: steamcontent.com) -> direct
          domain(suffix: steampipe.akamaized.net) -> direct
          domain(suffix: steam4shared.com) -> direct
    
          # 【修正】Steam 國內下載/語音直連
          domain(geosite: steam@cn) -> direct

          # 【修正】Steam 商店、社群、圖片 CDN 強制走代理
          domain(geosite: steam) -> for1
          domain(suffix: steamstatic.com) -> for1
          domain(suffix: steampowered.com) -> for1
          domain(suffix: steamcommunity.com) -> for1
          domain(suffix: steamusercontent.com) -> for1
          domain(suffix: akamaized.net) -> for1
          domain(suffix: fastly.net) -> for1

          # 3. 强制让本地的网络管理器（NetworkManager）和系统内核流量直连
          pname(NetworkManager, nm-dispatcher, dhcpcd, systemd-resolved, systemd-networkd, wpa_supplicant, iwd, dae) -> direct

          # DNS直連防回環
           dip(223.5.5.5, 223.6.6.6, 119.29.29.29, 8.8.8.8, 192.168.1.0/24, 192.168.2.0/24, 192.168.99.0/24) -> direct
          
          # 22 port
          dip(192.168.2.0/24) && dport(22) -> google_ai
          # dport(22) -> for1

          # ⭐️【第 1 級：核心修復 3】正式加入 Geo 國內流量全直連！
          # （不管台灣節點卡死成什麼樣，所有國內網站 100% 走本機千兆直連，絕不掉線！）
          domain(geosite:cn) -> direct
          dip(geoip:cn) -> direct

          # 補充特定直連域名
          domain(suffix: z.luxury, suffix: rockey-repo.org) -> direct(must)
          domain(suffix: edu.cn) -> direct(must)
          domain(suffix: valve.net) -> direct(must)

          # 1. Discord 核心全家桶（API + Gateway WebSocket + 媒体 CDN）
          domain(suffix: discord.gg) -> for46
          domain(suffix: discord.com) -> for46
          domain(suffix: discordapp.com) -> for46
          domain(suffix: discordapp.net) -> for46
          domain(suffix: discord.media) -> for46
          domain(suffix: gateway.discord.gg) -> for46

          # ⭐️【第 2 級】：Google AI 專屬池
          domain(suffix: aistudio.google.com) -> google_ai
          domain(suffix: google, suffix: google.dev, suffix: ai.google.dev) -> google_ai
          domain(suffix: gstatic.com, suffix: googleapis.com) -> google_ai
          domain(suffix: googleusercontent.com, suffix: gemini.google.com) -> google_ai
          domain(suffix: makersuite.google.com, suffix: alkalimakersuite.googleapis.com) -> google_ai
          domain(suffix: generativelanguage.googleapis.com, suffix: clients6.google.com) -> google_ai
          domain(suffix: chatgpt) -> google_ai

          # ⭐️【第 3 級】：開發與特定應用走代理
          pname(git) -> for1
          domain(suffix: github.com, suffix: gitlab.com, suffix: githubusercontent.com) -> for1
          domain(suffix: gitee.com) -> direct
          domain(suffix: itch.io) -> google_ai
          pname(curl, wget) -> for1
          # 修正筆誤：google-chrome 是進程名 (pname)，不是 domain
          pname(google-chrome, chrome, discord) -> for1
          domain(suffix: mega.nz) -> for1
          domain(suffix:discord) -> for146
          # 直连下载会遭遇严重的GFW丢包、连接重置和反复重试。
          # 这进一步打烂Wi-Fi 吞吐，导致 dae 的后台探测包彻底发不出去。
          pname(aria2c) && !domain(geosite:cn) -> for1
          pname(fi6s) -> for1

          dip(geoip:private) -> direct(must)
          # ⭐️【終極兜底】：國外未知流量走 1倍 for1 省錢池！
          fallback: for1
      }
    '';
  };
}
