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
          lan_interface: wlp8s0, auto
          wan_interface: auto
          dial_mode: domain
          log_level: info
          auto_config_kernel_parameter: true
          tproxy_port: 7890
          # 尝试把 DNS 监听绑定到本地回环地址
          # dns_listen: 127.0.0.1:53 
          tproxy_port_protect: true
          # 🌟【核心降級修復】縮短健康度探測間隔與超時時間
          # 預設 1800s 太久了！改成 30 秒探測一次，一旦節點死掉立刻剔除
          check_interval: 1300s
          # 探測超時時間縮短到 2 秒（原本預設太長，導致系統一直在死等超時）
          check_tolerance: 13s
      }

      subscription {
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY'
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=4'
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=3'
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=2'
          my_sub: 'https://links.rockey-repo.org/s/CEYCDf96zE5dU6gY?sub=1'
          my_sub: 'https://link.rockey-repo.org/link/CEYCDf96zE5dU6gY'
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
          # cfdns: 'tcp+udp://1.0.0.1:53'
          cf_doh3: 'https://1.1.1.1/dns-query'
        }
        routing {
          request {
            qtype(https) -> reject
            # qtype(aaaa) -> reject

            # 2. ✨【您的指定】所有 Google 網域強制走自己的 googledns (8.8.8.8)
            qname(geosite:google) -> googledns

            # 3. ✨【您的指定】除了 Google 以外的其他國外網域，走 cf_doh3
            !qname(geosite:cn) -> cfdns

            fallback: ali_h3
          }
          response {
            # 信任我們啟用的安全上游
            upstream(googledns) -> accept
            upstream(cfdns) -> accept
            upstream(ali_h3) -> accept
            ip(geoip:private) && !qname(geosite:cn) -> cf_doh3
            fallback: accept
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

          for4 {
              # policy: min_moving_avg
              policy: random
              filter: subtag(my_sub) && name(regex: '4倍') && !name(regex: '剩余|到期')
          }
          
          for46 {
              # policy: min_moving_avg
              policy: random
              filter: subtag(my_sub) && name(regex: 'I|REALITY') && !name(regex: '剩余|到期')
          }

          for146 {
              policy: min_moving_avg
              filter: subtag(my_sub) && !name(regex: '剩余|到期')
          }

          google_ai {
              # policy: min_moving_avg
              policy: random
              filter: subtag(my_sub)  && name(regex: '1|4|6|I') && !name(regex: 'HK|广州|剩余|到期')
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
          dport(22) -> for1

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

          dip(geoip:private) -> direct(must)
          # ⭐️【終極兜底】：國外未知流量走 1倍 for1 省錢池！
          fallback: for1
      }
    '';
  };
}
