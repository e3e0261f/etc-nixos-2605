{ pkgs, ... }:

{
  services.keyd = {
  enable = true;
  keyboards = {
    default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(caps_mod, capslock)";
          
          # 按一下 Scroll Lock 鍵，在日常模式與遊戲模式之間切換
          # （也可以改成 pause = "toggle(game)" 或其他平時不用的鍵）
          # scrolllock = "toggle(game)";
          "C-A-g" = "toggle(game)";
          insert = "toggle(game)";
        };

        caps_mod = {
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

        # 遊戲模式層：把 capslock 還原為原本純粹的鍵，不做任何攔截
        game = {
          capslock = "capslock";
        };
      };
    };
  };
};
}
