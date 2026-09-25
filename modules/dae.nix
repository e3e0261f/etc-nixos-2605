# /etc/nixos/modules/dae-h3.nix (或 dae.nix)
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
    "net.ipv6.conf.all.forwarding" = 1;
  };

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
          log_level: info
          auto_config_kernel_parameter: true
          tproxy_port: 7890
          tproxy_port_protect: true
      }

      subscription {
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY'
      }

      # =======================================================
      # ⭐️ 穩定極速 DNS 解析
      # =======================================================
      dns {
        upstream {
          ali_h3: 'h3://223.5.5.5:443/dns-query'
          alidns: 'udp://223.5.5.5:53'
          googledns: 'tcp+udp://8.8.8.8:53'
          cf_doh3: 'https://cloudflare-dns.com/dns-query'
        }
        routing {
          request {
            qname(geosite:cn) -> alidns
            # 兜底走 alidns，絕不死鎖等待代理
            fallback: alidns
          }
        }
      }

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
          # ⭐️【第 0 級最高優先】：系統底層、遊戲與核心直連
          pname(Albion-Online, Albion-Online.bin, albion-online) -> direct(must)
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


          # ⭐️【終極兜底】：國外未知流量走 1倍 for1 省錢池！
          fallback: for1
      }
    '';
  };
}
