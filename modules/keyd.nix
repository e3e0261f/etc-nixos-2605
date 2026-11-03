{ pkgs, ... }:

{
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            # ⭐️ 1. 让 CapsLock 彻底变成 Insert 键（保留长按功能）
            capslock = "overload(ins_mod, insert)";
            insert = "overload(ins_mod, insert)";

            # 🚀 2. 无延迟后输优先（按下 A 立即切到 a 激活层，下同）
            a = "setlayer(a_active, a)";
            d = "setlayer(d_active, d)";
            w = "setlayer(w_active, w)";
            s = "setlayer(s_active, s)";

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

          # 🚀 4. A 键正在被按住的层（此时 A 生效中）
          a_active = {
            # 关键：当按着 A 的时候按下 D，不仅要触发 D，还要强行清掉 A 的输出！
            d = "clear(a_active) d";
          };

          # 🚀 5. D 键正在被按住的层（此时 D 生效中）
          d_active = {
            # 关键：当按着 D 的时候按下 A，不仅要触发 A，还要强行清掉 D 的输出！
            a = "clear(d_active) a";
          };

          # 🚀 6. W 和 S 的动态互解层
          w_active = {
            s = "clear(w_active) s";
          };
          s_active = {
            w = "clear(s_active) w";
          };

          # 🎮 7. 游戏模式层
          game = {
            capslock = "insert";
            insert = "insert";
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
