{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = false; # 先讓給 Nvim，想換 Helix 再改
    viAlias = true;
    vimAlias = true;

    configure = {
      # --- 核心：由 Nix 預裝高亮包，不再需要編譯器和網路 ---
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [ 
          # 這裡放入你想支援的語言，Nix 會自動幫你下載編譯好的 .so 檔案
          (nvim-treesitter.withPlugins (p: with p; [ 
            nix lua vim vimdoc query bash c python markdown markdown_inline html css typescript javascript
          ]))
        ];
      };

      customRC = ''
        lua << EOF
        -- 1. 禁用自動下載，徹底終止報錯
        require'nvim-treesitter.configs'.setup {
          ensure_installed = {}, -- 留空，因為 Nix 已經裝好了
          auto_install = false,  -- 👈 最重要的一行：禁止 Nvim 自己下載
          highlight = {
            enable = true,
          },
        }

        -- (保留你之前的魔法：自動建立目錄、:W、快捷鍵等)
        -- 自動建立目錄
        vim.api.nvim_create_autocmd({ "BufWritePre" }, {
          group = vim.api.nvim_create_augroup("auto_create_dir", { clear = true }),
          callback = function(event)
            if event.match:match("^%w%w+:[\\/][\\/]") then return end
            local file = vim.loop.fs_realpath(event.match) or event.match
            vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
          end,
        })

        -- 快捷鍵
        local map = vim.keymap.set
        local opts = { noremap = true, silent = true }
        map({'n', 'i', 'v'}, '<C-s>', '<Esc>:w<CR>', opts)
        map({'n', 'i', 'v'}, '<A-x>', '<Esc>dd', opts)
        map({'n', 'i', 'v'}, 'ZZ', '<Esc>ZZ', opts)
        vim.api.nvim_create_user_command('W', function() vim.cmd('w !sudo tee % > /dev/null') end, {})
        
        vim.opt.clipboard = "unnamedplus"
        EOF
      '';
    };
  };
}
