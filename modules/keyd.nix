{ pkgs, ... }:

{
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            # ⭐️ 1. 让 CapsLock 彻底变成 Insert 键
            capslock = "overload(ins_mod, insert)";
            insert = "overload(ins_mod, insert)";

            # 🚀 2. WASD 动态覆盖（SOCD 后输优先）
            a = "overload(a_layer, a)";
            d = "overload(d_layer, d)";
            w = "overload(w_layer, w)";
            s = "overload(s_layer, s)";

            # 保留备用的快捷键
            "C-A-g" = "toggle(game)";
          };

          # ⭐️ 3. 核心层：按住这个键（Insert / 原Caps）时的所有动作
          ins_mod = {
            space = "enter";
            w = "up";
            a = "left";
            s = "down";
            d = "right";
            h = "left";
            j = "down";
            k = "up";
            l = "right";
          };

          # 🚀 4. 定义 WASD 互相清除的防冲突层
          a_layer = {
            d = "clear(a) d";
          };
          d_layer = {
            a = "clear(d) a";
          };
          w_layer = {
            s = "clear(w) s";
          };
          s_layer = {
            w = "clear(s) w";
          };

          # 🎮 5. 游戏模式层
          # 当你按下 Ctrl+Alt+G 切换到此层时，WASD 将会被恢复为普通按键（不触发防冲突）
          game = {
            capslock = "insert";
            insert = "insert";
            # 显式重置 WASD，防止它们继承 main 层的 overload 行为
            a = "a";
            d = "d";
            w = "w";
            s = "s";
          };
        };
      };
    };
  };
}
