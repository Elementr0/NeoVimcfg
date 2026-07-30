
-- Установка lazy.nvim, если он отсутствует
vim.opt.number =  true
vim.opt.relativenumber  = true
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- последняя стабильная версия
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Устанавливаем пробел как клавишу лидера (нужно для горячих клавиш вроде <leader>e)
vim.g.mapleader = " "

-- Настройка плагинов через lazy
require("lazy").setup({
  -- Тема оформления
  {
    "folke/tokyonight.nvim",
    lazy = false,    -- загружается сразу при старте
    priority = 1000, -- загрузить тему в первую очередь
    config = function()
      -- Выбор конкретного стиля ("night", "storm" или "moon")
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  },

  -- Строка состояния (lualine) с поддержкой иконок (требует Nerd Font)
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          -- Используем встроенную тему, идеально подходящую под tokyonight
          theme = 'tokyonight',
          
          -- Красивые скругленные разделители по краям блоков
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
          
          -- Отключаем вывод имен файлов в строке, если они дублируются (по желанию)
          disabled_filetypes = {
            statusline = { "alpha", "lazy", "NvimTree" },
          },
          always_divide_middle = true,
        },
        sections = {
          lualine_a = { { 'mode', separator = { left = '', right = '' }, right_padding = 2 } },
          lualine_b = { 'filename', 'branch' },
          lualine_c = { 'diff' },
          lualine_x = { 'diagnostics', 'encoding', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { { 'location', separator = { left = '', right = '' }, left_padding = 2 } },
        },
      })
    end,
  },

  -- Дерево файлов (Nvim-tree в виде плавающего окна)
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require("nvim-tree").setup({
        view = {
          float = {
            enable = true,
            open_win_config = function()
              local screen_w = vim.opt.columns:get()
              local screen_h = vim.opt.lines:get()
              local window_w = math.floor(screen_w * 0.6)
              local window_h = math.floor(screen_h * 0.6)
              local center_x = (screen_w - window_w) / 2
              local center_y = (screen_h - window_h) / 2

              return {
                border = 'rounded',
                relative = 'editor',
                row = center_y,
                col = center_x,
                width = window_w,
                height = window_h,
              }
            end,
          },
          width = 30,
        },
      })

      -- Горячая клавиша: Пробел + e (открыть/закрыть дерево)
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true, desc = 'Toggle NvimTree Float' })
    end,
  },

  -- Умный поиск и навигация (Telescope)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')

      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
    end,
  },

  -- Продвинутая подсветка синтаксиса (Treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { "lua", "c", "cpp", "python", "html", "css", "javascript", "bash", "asm" },
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },

  -- Автоматическое закрытие скобок и кавычек
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },

   -- Выдвижной терминал
  {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 15,                -- высота нижнего терминала
        -- Убираем open_mapping, чтобы он не перехватывал клавиши в режиме вставки
        direction = 'horizontal', 
        shade_terminals = true,
      })

      -- Назначаем открытие/закрытие терминала только для NORMAL режима (<leader>t)
      vim.keymap.set('n', '<leader>t', '<cmd>ToggleTerm<CR>', { noremap = true, silent = true })

      -- Удобный выход из режима терминала в нормальный режим по Esc
      function _G.set_terminal_keymaps()
        local opts = {buffer = 0}
        vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
      end

      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
    end,
  },

  -- Менеджер бинарников (LSP, DAP)
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },

  -- Интеграция Mason и LSP
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd" },
      })
    end,
  },

  -- Настройка языкового сервера для Си/C++ (современный API)
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      vim.lsp.config('clangd', {
        cmd = { 'clangd' },
        capabilities = capabilities,
      })
      vim.lsp.enable('clangd')
    end,
  },

  -- Дополнительные фичи для clangd (память структур, переключение заголовочных файлов)
  {
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp" },
    config = function()
      require("clangd_extensions").setup()
    end,
  },

  -- Движок автодополнения
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        })
      })
    end,
  },
    -- Горячие клавиши для работы с LSP (переходы по коду)
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      vim.lsp.config('clangd', {
        cmd = { 'clangd' },
        capabilities = capabilities,
      })
      vim.lsp.enable('clangd')

      -- Настройка горячих клавиш при подключении LSP к буферу
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local opts = { buffer = args.buf }
          -- Переход к определению (включая #include файлы)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          -- Показать информацию о переменной/функции под курсором
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          -- Переход к объявлению
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          -- Поиск всех мест использования (references)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        end,
      })
    end,
  },
})
