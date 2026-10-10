# /etc/nixos/modules/apps/apps-gui.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
              # Rust 开发工具链
          rustc
          cargo
          clippy
          rustfmt
          
          # 网页编译目标 (WebAssembly)
          wasm-bindgen-cli
          
          # 项目构建工具
          trunk
          lld
          
          # 系统依赖
          pkg-config
          libxkbcommon
          libGL
          wayland
          libX11
          libXcursor
          libXi
          libXrandr
  ];
}
