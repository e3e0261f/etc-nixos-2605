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

        };
      };
    };
  };
}
