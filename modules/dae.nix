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
  services.dae = {
    enable = true;
    assets = [ my-dae-assets ];

    config = ''
      global {
          allow_insecure: false
          so_mark_from_dae: 0
          lan_interface: auto
          wan_interface: auto
          dial_mode: domain
          log_level: info
          check_interval: 1800s
          auto_config_kernel_parameter: true
          tproxy_port: 7890
          tproxy_port_protect: true
      }

      subscription {
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY'
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=4'
          my_sub: 'https://link.rockey-repo.org/link/CEYCDf96zE5dU6gY'
          # 旧版clash订阅 (含ssr节点):
          my_sub: 'https://link.rockey-repo.org/link/CEYCDf96zE5dU6gY?clash=2'
  
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
          cfdns: 'tcp+udp://1.1.1.1:53'
          cf_doh3: 'https://1.1.1.1/dns-query'
        }
        routing {
          request {
            qtype(https) -> reject
            !qname(geosite:cn) -> cf_doh3
            qtype(aaaa) -> reject
            fallback: alidns
          }
          response {
            # upstream(googledns) -> accept
            upstream(cf_doh3) -> accept
            # ip(geoip:private) && !qname(geosite:cn) -> googledns
            ip(geoip:private) && !qname(geosite:cn) -> cf_doh3
            fallback: accept
          }
        }
      }

      # dns {
      #   upstream {
      #     ali_h3: 'h3://223.5.5.5:443/dns-query'
      #     alidns: 'udp://223.5.5.5:53'
      #     googledns: 'tcp+udp://8.8.8.8:53'
      #     cf_doh3: 'https://cloudflare-dns.com/dns-query'
      #     cfdns: 'tcp+udp://1.1.1.1:53'
      #     # alih3: 'h3://dns.alidns.com:443'
      #     # alih3_path: 'h3://dns.alidns.com:443/dns-query'
      #     # alihttp3: 'http3://dns.alidns.com:443'
      #     # alihttp3_path: 'http3://dns.alidns.com:443/dns-query'
      #     # ali_quic: 'quic://dns.alidns.com:853'

      #     # h3_custom_path: 'h3://dns.example.com:443/custom-path'
      #     # http3_custom_path: 'http3://dns.example.com:443/custom-path'

      #     # ali_doh: 'https://dns.alidns.com:443'
      #     # ali_dot: 'tls://dns.alidns.com:853'

      #     # doh_custom_path: 'https://dns.example.com:443/custom-path'
      #     # udp_check_dns: 'dns.google:53,8.8.8.8,2001:4860:4860::8888'
      #     # check_interval: 30s
      #     # 
      #   }
      #   routing {
      #     request {
      #       !qname(geosite:cn) -> cfdns

      #       fallback: ali_h3
      #     }
      #     response {
      #       upstream(cfdns) -> accept
      #       fallback: accept
      #     }
      #   }
      # }

      # =======================================================
      # ⭐️ 核心節點池
      # =======================================================
      group {
          for1 {
              policy: min_moving_avg
              filter: subtag(my_sub) && !name(regex: '4倍|6倍|剩余|到期')
          }

          for146 {
              policy: min_moving_avg
              filter: subtag(my_sub) && !name(regex: '剩余|到期')
          }

          google_ai {
              policy: min_moving_avg
              filter: subtag(my_sub) && !name(regex: 'HK|香港|广州|剩余|到期|4倍|6倍|BGP')
          }

          for4 {
              policy: min_moving_avg
              filter: subtag(my_sub) && name(regex: '4倍') && !name(regex: '剩余|到期')
          }
          
          for46 {
              policy: min_moving_avg
              filter: subtag(my_sub) && name(regex: '4倍|6倍') && !name(regex: '剩余|到期')
          }
      }

      # =======================================================
      # ⭐️ 路由分流規則（嚴格從上到下匹配）
      # =======================================================
      routing {
          # dport(443) && l4proto(udp) -> block
          ipversion(6) -> block
          # ⭐️【第 0 級最高優先】：系統底層、遊戲與核心直連
          pname(Albion-Online, albion-online) -> direct(must)
          pname(cloudflared) -> direct(must)
          domain(keyword: "argotunnel.com") -> direct
          domain(keyword: "cloudflare.com") -> direct
          domain(suffix: albiononline.com) -> direct(must)
          pname(gix, steam) -> direct(must)
          # wow
          domain(suffix: battle.net) -> direct
          domain(keyword: blizzard, "battle.net") -> direct
          # pname(Battle.net.exe, Agent.exe, Wow.exe) -> direct
          # pname(wine, wineserver, winedevice.exe) -> direct

          # 3. 强制让本地的网络管理器（NetworkManager）和系统内核流量直连
          pname(NetworkManager, nm-dispatcher, dhcpcd, systemd-resolved, systemd-networkd, wpa_supplicant, iwd, dae) -> direct
          # 4. 强制排除局域网和 DHCP 自动分配的本地子网（防止握手流量被代理）
          dip(224.0.0.0/24, 239.0.0.0/8) -> direct
          dip(192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12) -> direct
          port(53) -> direct

          # 國內 DNS (阿里) 直連防回環
          dip(223.5.5.5, 223.6.6.6, 119.29.29.29) -> direct

          # ⭐️【防 GFW 投毒】：國外 DNS 查詢塞入代理隧道
          dip(8.8.8.8, 8.8.4.4) -> for1
          dip(192.168.2.0/24) && dport(22) -> google_ai

          # ⭐️【第 1 級：核心修復 3】正式加入 Geo 國內流量全直連！
          # （不管台灣節點卡死成什麼樣，所有國內網站 100% 走本機千兆直連，絕不掉線！）
          domain(geosite:cn) -> direct
          dip(geoip:cn) -> direct

          # 補充特定直連域名
          domain(suffix: miwifi.com, suffix: xiaomi.com, suffix: mi.com) -> direct(must)
          domain(suffix: z.luxury, suffix: rockey-repo.org) -> direct(must)
          domain(suffix: edu.cn) -> direct(must)

          # 1. Discord 核心全家桶（API + Gateway WebSocket + 媒体 CDN）
          domain(suffix: discord.gg) -> for146
          domain(suffix: discord.com) -> for146
          domain(suffix: discordapp.com) -> for146
          domain(suffix: discordapp.net) -> for146
          domain(suffix: discord.media) -> for146
          domain(suffix: gateway.discord.gg) -> for146

          # ⭐️【第 2 級】：Google AI 專屬池
          domain(suffix: aistudio.google.com) -> google_ai
          domain(suffix: google.dev, suffix: ai.google.dev) -> google_ai
          domain(suffix: gstatic.com, suffix: googleapis.com) -> google_ai
          domain(suffix: googleusercontent.com, suffix: gemini.google.com) -> google_ai
          domain(suffix: makersuite.google.com, suffix: alkalimakersuite.googleapis.com) -> google_ai
          domain(suffix: generativelanguage.googleapis.com, suffix: clients6.google.com) -> google_ai
          domain(suffix: chatgpt) -> google_ai

          # ⭐️【第 3 級】：開發與特定應用走代理
          pname(git) -> for1
          domain(suffix: github.com, suffix: gitlab.com, suffix: githubusercontent.com) -> for1
          domain(suffix: gitee.com) -> direct
          pname(nix-daemon, nix, curl, wget) -> for1
          # 修正筆誤：google-chrome 是進程名 (pname)，不是 domain
          pname(google-chrome, chrome, discord) -> for1
          domain(suffix: mega.nz) -> for1
          dport(22) -> for1
          domain(suffix:discord) -> for146
          # 直连下载会遭遇严重的GFW丢包、连接重置和反复重试。
          # 这进一步打烂Wi-Fi 吞吐，导致 dae 的后台探测包彻底发不出去。
          pname(aria2c) && !domain(geosite:cn) -> for1

          # ⭐️【終極兜底】：國外未知流量走 1倍 for1 省錢池！
          fallback: for1
      }
    '';
  };
}
