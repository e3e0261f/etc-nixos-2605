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
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
  };

  services.dae = {
    enable = true;
    assets = [ my-dae-assets ];

    config = ''
      global {
          allow_insecure: false
          so_mark_from_dae: 0
          lan_interface: auto
          wan_interface: wlp8s0, auto
          dial_mode: domain
          log_level: info
          auto_config_kernel_parameter: true
          tproxy_port: 7890
          tproxy_port_protect: true

          # ⭐️【关键修复 1】：dae 全局彻底禁用 IPv6 健康检查与节点探测
          disable_ipv6: true
      }

      subscription {
          my_sub: 'https://link.rockey-repo.org/link/CEYCDf96zE5dU6gY'
      }

      # =======================================================
      # ⭐️ 稳定极速 DNS 解析
      # =======================================================
      dns {
        # ⭐️【关键修复 2】：禁用 DNS 响应 AAAA (IPv6) 记录，强制客户端降级回 IPv4
        disable_ipv6: true

        upstream {
          ali_h3: 'h3://223.5.5.5:443/dns-query'
          alidns: 'udp://223.5.5.5:53'
          googledns: 'tcp+udp://8.8.8.8:53'
          cf_doh3: 'https://cloudflare-dns.com/dns-query'
          cfdns: 'tcp+udp://1.1.1.1:53'
        }
        routing {
          request {
            # qname(geosite:cn) -> ali_h3
            fallback: cfdns
          }
        }
      }

      # =======================================================
      # ⭐️ 核心节点池
      # =======================================================
      # 提示：过滤掉了带有 [ss] 或 2022-blake3 等 dae 不支持的 SS-2022 节点
      group {
          for1 {
              policy: min_moving_avg
              filter: subtag(my_sub) && !name(regex: '4倍|6倍|剩余|到期') && !name(regex: '^\[ss\]')
          }

          for146 {
              policy: min_moving_avg
              filter: subtag(my_sub) && !name(regex: '剩余|到期') && !name(regex: '^\[ss\]')
          }

          google_ai {
              policy: min_moving_avg
              filter: subtag(my_sub) && !name(regex: 'HK|香港|广州|剩余|到期|4倍|6倍|BGP') && !name(regex: '^\[ss\]')
          }

          for4 {
              policy: min_moving_avg
              filter: subtag(my_sub) && name(regex: '4倍') && !name(regex: '剩余|到期') && !name(regex: '^\[ss\]')
          }
          
          for46 {
              policy: min_moving_avg
              filter: subtag(my_sub) && name(regex: '4倍|6倍') && !name(regex: '剩余|到期') && !name(regex: '^\[ss\]')
          }
      }

      # =======================================================
      # ⭐️ 路由分流规则（严格从上到下匹配）
      # =======================================================
      routing {
          # ⭐️【关键修复 3】：在路由最顶端将所有 IPv6 流量阻断丢弃，防止遗留连接冲破代理
          ip(v6) -> block

          # ⭐️【第 0 级最高优先】：系统底层、游戏与核心直连
          pname(Albion-Online, Albion-Online.bin, albion-online) -> direct(must)
          domain(suffix: albiononline.com) -> direct(must)

          # 内网 / 本机 IP 直连
          dip(192.168.0.0/16, 127.0.0.0/8) && dport(22) -> direct
          dip(127.0.0.0/8, 192.168.0.0/16) -> direct
          pname(gix, aria2c, steam) -> direct(must)

          # 国内 DNS (阿里) 直连防回环
          dip(223.5.5.5, 223.6.6.6) -> direct(must)
          domain(full: dns.alidns.com) -> direct(must)
          pname(systemd-resolved, dnsmasq, NetworkManager, dae) -> direct(must)

          # ⭐️【防 GFW 投毒】：国外 DNS 查询塞入代理隧道
          dip(8.8.8.8, 8.8.4.4) -> for1
          dip(192.168.2.0/24) && dport(22) -> google_ai

          # ⭐️【第 1 级】：Geo 国内流量全直连
          domain(geosite:cn) -> direct
          dip(geoip:cn) -> direct

          # 补充特定直连域名
          domain(suffix: miwifi.com, suffix: xiaomi.com, suffix: mi.com) -> direct(must)
          domain(suffix: z.luxury, suffix: rockey-repo.org) -> direct(must)
          domain(suffix: edu.cn) -> direct(must)

          # ⭐️【第 2 级】：Google AI 专属池
          domain(suffix: aistudio.google.com) -> google_ai
          domain(suffix: google.dev, suffix: ai.google.dev) -> google_ai
          domain(suffix: gstatic.com, suffix: googleapis.com) -> google_ai
          domain(suffix: googleusercontent.com, suffix: gemini.google.com) -> google_ai
          domain(suffix: makersuite.google.com, suffix: alkalimakersuite.googleapis.com) -> google_ai
          domain(suffix: generativelanguage.googleapis.com, suffix: clients6.google.com) -> google_ai

          # ⭐️【第 3 级】：开发与特定应用走代理
          pname(git) -> for1
          domain(suffix: github.com, suffix: gitlab.com, suffix: githubusercontent.com) -> for1
          domain(suffix: gitee.com) -> direct
          pname(nix-daemon, nix, curl, wget) -> for1
          pname(google-chrome, chrome, discord) -> for1
          domain(suffix: mega.nz) -> for1
          dport(22) -> for1
          # ⭐️【关键修复 4】：补全域名匹配语法中的点
          domain(suffix: discord.com) -> for146

          # ⭐️【终极兜底】：国外未知流量走 1倍 for1 省钱池！
          fallback: for1
      }
    '';
  };
}
