{ pkgs, ... }:

{
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            # ⭐️ 1. 让 CapsLock 彻底变成 Insert 键！
            # 无论按物理 CapsLock 还是物理 Insert，统统都是 overload(ins_mod, insert)
            capslock = "overload(ins_mod, insert)";
            insert = "overload(ins_mod, insert)";

            # 保留备用的快捷键
            "C-A-g" = "toggle(game)";
          };

          # ⭐️ 2. 核心层：按住这个键（Insert / 原Caps）时的所有动作
          ins_mod = {
            # 💡 按住它 + 空格 = 直接触发回车 (Enter)！
            space = "enter";

            # 按住它 + WASD / HJKL = 方向键
            w = "up";
            a = "left";
            s = "down";
            d = "right";
            h = "left";
            j = "down";
            k = "up";
            l = "right";
          };

          # 游戏模式层（纯备用）
          game = {
            capslock = "insert";
            insert = "insert";
          };
        };
      };
    };
  };
}
