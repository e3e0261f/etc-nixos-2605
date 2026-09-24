# cf_h3e_family: 'https://security.cloudflare-dns.com/dns-query'
# # 封鎖惡意軟體、成人內容
# cf_h3e_sec: 'https://family.cloudflare-dns.com/dns-query'
# cf_doh3: '1dot1dot1dot1.cloudflare-dns.com'
# cf_doh3_domains: 'https://cloudflare-dns.com/dns-query'
# cf_doh3_ip: 'https://1.1.1.1/dns-query'
# cf_h3_1: 'h3://1.1.1.1:443/dns-query'
# cf_h3_2: 'h3://1.0.0.1:443/dns-query'
# # 國外備用：Google DoH3
# google_h3: 'h3://8.8.8.8:443/dns-query'
# # 國內主解析：阿里 DoH3（國內直連，極速無污染）
# ali_h3: 'h3://223.5.5.5:443/dns-query'
# cfdns: 'tcp+udp://1.1.1.1:53'
# googledns: 'tcp+udp://8.8.8.8:53'
# alidns: 'udp://dns.alidns.com:53'
# 2. 海外域名交給 NextDNS，享有乾淨、無污染且能擋廣告的解析
# nextdns: 'https://nextdns.io'
# /etc/nixos/modules/dae-h3.nix (或 dae.nix)
{ pkgs, inputs, ... }:

{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.dae = {
    enable = true;
    config = ''
      global {
          allow_insecure: false
          so_mark_from_dae: 0
          lan_interface: auto
          wan_interface: auto
          log_level: info
          auto_config_kernel_parameter: true
          tproxy_port: 7890
          tproxy_port_protect: true
      }

      subscription {
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY'
      }

      # =======================================================
      # ⭐️ 穩定極速 DNS 解析 (TCP 長連接 + 阿里直連)
      # =======================================================
      dns {
        upstream {
          cf_doh3_domains: 'https://cloudflare-dns.com/dns-query'
          ali_h3: 'h3://223.5.5.5:443/dns-query'
        }
        routing {
          request {
            fallback: ali_h3
          }
        }
      }

      # =======================================================
      # ⭐️ 核心節點池（拿掉誤殺 REALITY 節點的「直連」字眼）
      # =======================================================
      group {
          # 1. 大流量省錢池：排除 4倍、6倍、公告、香港
          for1 {
              # policy: min_moving_avg
              policy: random
              # policy: fixed(2)
              filter: subtag(my_sub) && !name(regex: '4倍|6倍|剩余|到期')
          }

          for146 {
              # policy: min_moving_avg
              policy: random
              # policy: fixed(2)
              filter: subtag(my_sub) && !name(regex: '剩余|到期')
          }

          # 2. Google AI 專用池：排除 HK、廣州、4倍、6倍與公告
          google_ai {
              policy: min_moving_avg
              # policy: fixed(1)
              # policy: random
              filter: subtag(my_sub) && !name(regex: 'HK|香港|广州|剩余|到期|4倍|6倍|BGP')
          }

          # 4倍
          for4 {
              policy: min_moving_avg
              # policy: random
              # policy: fixed(1)
              filter: subtag(my_sub) && name(regex: '4倍') && !name(regex: '剩余|到期')
          }
          
          # 3. 4倍/6倍 專用池：專門用來救急
          for46 {
              policy: min_moving_avg
              # policy: random
              # policy: fixed(1)
              filter: subtag(my_sub) && name(regex: '4倍|6倍') && !name(regex: '剩余|到期')
          }
      }

      # =======================================================
      # ⭐️ 路由分流規則（嚴格從上到下匹配）
      # =======================================================
      routing {
          # ⭐️【第 0 級最高優先】：系統構建、遊戲與本地服務【絕對直連】
          # 1. 阿爾比恩全流量直連放行（交給路由器 UU 加速器專線處理！）
          pname(Albion-Online, Albion-Online.bin, albion-online) -> direct(must)
          domain(suffix: albiononline.com) -> direct(must)
          domain(suffix: githubusercontent.com) -> for1

          pname(gix, aria2c, steam) -> direct(must)
          pname(nix-daemon) -> for1

          # 3. 國內 DNS (阿里) 與核心防回環
          dip(223.5.5.5, 223.6.6.6) -> direct(must)
          dip(4.3.2.1) -> direct(must)
          

          domain(full: dns.alidns.com) -> direct(must)
          pname(systemd-resolved, dnsmasq, NetworkManager, dae) -> direct(must)

          # ⭐️【第 1 級】：國外 DNS (8.8.8.8) 塞入代理隧道
          dip(8.8.8.8, 8.8.4.4) && dport(443) -> google_ai
          dip(192.168.2.0/24) && dport(22) -> google_ai

          # ⭐️【第 2 級】：國內服務直連
          domain(suffix: miwifi.com) -> direct(must)
          domain(suffix: xiaomi.com) -> direct(must)
          domain(suffix: mi.com) -> direct(must)
          domain(suffix: z.luxury) -> direct
          domain(suffix: rockey-repo.org) -> direct
          domain(suffix: edu.cn) -> direct(must)
          

          # ⭐️【第 3 級】：Google AI 與相關服務（修正語法，拿掉錯誤的 must）
          domain(suffix: aistudio.google.com) -> google_ai
          domain(suffix: google.dev) -> google_ai
          domain(suffix: ai.google.dev) -> google_ai
          domain(suffix: gemini.google.com) -> google_ai
          domain(suffix: makersuite.google.com) -> google_ai
          domain(suffix: alkalimakersuite.googleapis.com) -> google_ai
          domain(suffix: generativelanguage.googleapis.com) -> google_ai
          domain(suffix: clients6.google.com) -> google_ai

          # ⭐️ Add Git routing here:
          # Route Git process traffic and common code-hosting domains to your proxy pool
          pname(git) -> for1
          domain(suffix: github) -> for1
          domain(suffix: gitlab) -> for1
          domain(suffix: gitee) -> for1 # If you use Gitee, or keep it direct/fallback


          # ⭐️【第 5 級】：阻斷普通網站的 QUIC (UDP 443) 享受 TCP 代理加速
          # l4proto(udp) && dport(443) -> block

          # Mega.nz 專用高速通道
          domain(suffix: mega.nz) -> for1
          pname(discord) -> for1

          # ⭐️【終極兜底】：預設走 1倍 for1 省錢池！（非常明智的改動！）
          fallback: for1
      }
    '';
  };
}
