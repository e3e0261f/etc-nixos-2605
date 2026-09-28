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
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    # 禁用 IPv6 的自动配置（Router Advertisement）
    # "net.ipv6.conf.all.disable_ipv6" = 1;
    # "net.ipv6.conf.default.disable_ipv6" = 1;
    # "net.ipv6.conf.lo.disable_ipv6" = 1;
    
    # 确保 dae 绑定的接口能够识别 IPv6 地址结构，但系统不会主动使用
    # 如果 dae 依然报错，你可以尝试只禁用 autoconf
    # "net.ipv6.conf.all.autoconf" = 0;
    # "net.ipv6.conf.all.accept_ra" = 0;
  };
  # 强制 NetworkManager 忽略 IPv6 设置
  # （防止连接 Wi-Fi/有线网时依然从路由器获取 IPv6 SLAAC/DHCPv6 地址）
  # environment.etc."NetworkManager/conf.d/00-disable-ipv6.conf".text = ''
  #   [connection]
  #   ipv6.method=ignore
  # '';


  services.dae = {
    enable = true;
    assets = [ my-dae-assets ];


    config = ''
      global {
          allow_insecure: false
          so_mark_from_dae: 0
          lan_interface: auto
          # ⭐️ 核心修復 2：鎖定你的 Wi-Fi 網卡，加入快速重連自愈 (5s)，杜絕登出斷網！
          wan_interface: wlp8s0, auto
          dial_mode: domain
          # log_level: info
          log_level: warn
          auto_config_kernel_parameter: true
          tproxy_port: 7890
          tproxy_port_protect: true
      }

      subscription {
          # my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY'
          # my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=4'
          my_sub: 'https://link.rockey-repo.org/link/CEYCDf96zE5dU6gY'
      }

      # =======================================================
      # ⭐️ 穩定極速 DNS 解析
      # =======================================================
      #

      dns {
        upstream {
          googledns: 'tcp+udp://dns.google:53'
          alidns: 'udp://dns.alidns.com:53'
        }
        routing {
          request {
            qtype(https) -> reject
            fallback: alidns
          }
          response {
            upstream(googledns) -> accept
            ip(geoip:private) && !qname(geosite:cn) -> googledns
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
          # ipversion(6) -> direct
          ipversion(6) -> block
          # ⭐️【第 0 級最高優先】：系統底層、遊戲與核心直連
          pname(Albion-Online, albion-online) -> direct(must)
          pname(cloudflared) -> direct(must)
          domain(keyword: "argotunnel.com") -> direct
          domain(keyword: "cloudflare.com") -> direct
          domain(suffix: albiononline.com) -> direct(must)

          # 內網 / 本機 IP 直連
          dip(192.168.0.0/16, 127.0.0.0/8) && dport(22) -> direct
          dip(127.0.0.0/8, 192.168.0.0/16) -> direct
          pname(gix, aria2c, steam) -> direct(must)

          # 國內 DNS (阿里) 直連防回環
          dip(223.5.5.5, 223.6.6.6) -> direct(must)
          domain(full: dns.alidns.com) -> direct(must)
          pname(systemd-resolved, dnsmasq, NetworkManager, dae) -> direct(must)

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

          # ⭐️【終極兜底】：國外未知流量走 1倍 for1 省錢池！
          fallback: for1
      }
    '';
  };
}
