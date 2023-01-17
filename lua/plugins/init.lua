-- Utility settings loader
local setup = function(mod, remote)
	return function()
		if remote == nil then
			-- If plugin does not need "require" setup, then just set it up.
			require(mod)
		else
			local status = pcall(require, remote)
			if not status then
				print(remote .. " is not downloaded.")
				return
			else
				local local_config = require(mod)
				if type(local_config) == "table" then
					return local_config.setup()
				end
			end
		end
	end
end

local fn = vim.fn
local lazypath = fn.stdpath("data") .. "lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local lazy = require("lazy")

lazy.setup({
	{
		"catppuccin/nvim",
		lazy = false, priority = 1000, config = function()
			vim.cmd([[colorscheme catppuccin-mocha]])
		end
	},
	{
		"hrsh7th/nvim-cmp",
		-- load cmp on InsertEnter
		event = "InsertEnter",
		-- these dependencies will only be loaded when cmp loads
		-- dependencies are always lazy-loaded unless specified otherwise
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline"
		},
	},
	{ "neovim/nvim-lspconfig" },
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "onsails/lspkind-nvim" },
	{ "nvim-lua/plenary.nvim" },
	{ "stevearc/aerial.nvim", config = setup("plugins.aerial"), event = "VeryLazy" },
	{ "rafamadriz/friendly-snippets" },
	{ "L3MON4D3/LuaSnip", config = setup("plugins.luasnip"), },
	{ "saadparwaiz1/cmp_luasnip" },
	{ "jose-elias-alvarez/null-ls.nvim", config = setup("plugins.null", "null-ls") },
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v2.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"kyazdani42/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = setup("plugins.neo-tree", "neo-tree"),
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
		config = setup("plugins.telescope", "telescope"),
	},
	{ "tpope/vim-dispatch" },
	{ "tpope/vim-repeat" },
	{ "tpope/vim-sleuth" },
	{ "tpope/vim-surround" },
	{ "tpope/vim-unimpaired" },
	{ "tpope/vim-eunuch" },
	{ "tpope/vim-obsession" },
	{ "tpope/vim-fugitive", config = setup("plugins.fugitive") },
	{ "junegunn/fzf", },
	{
		"startup-nvim/startup.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
		config = setup("plugins.startup"),
	},
	{
		"akinsho/bufferline.nvim",
		version = "v3.*",
		dependencies = { "kyazdani42/nvim-web-devicons" },
		config = setup("plugins.bufferline", "bufferline"),
	},
	{ "windwp/nvim-autopairs", config = setup("plugins.autopairs", "nvim-autopairs") } ,
	-- { "mfussenegger/nvim-dap", config = setup("plugins.nvim-dap") },
	-- { "qpkorr/vim-bufkill" },
	{ "numToStr/Comment.nvim", config = true, event = "VeryLazy"  },
	{ "numToStr/FTerm.nvim", config = setup("plugins.fterm", "FTerm") },
	{ "romainl/vim-cool" },
	{ "vim-scripts/BufOnly.vim", event = "VeryLazy" },
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "kyazdani42/nvim-web-devicons" },
		config = setup("plugins.lualine", "lualine"),
	},
	{
		"lewis6991/gitsigns.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = setup("plugins.gitsigns", "gitsigns"),
	},
	{ "p00f/nvim-ts-rainbow", dependencies = { "nvim-treesitter/nvim-treesitter" } },
	{"nvim-treesitter/nvim-treesitter-textobjects", dependencies = { "nvim-treesitter/nvim-treesitter" }},
	{ "kyazdani42/nvim-web-devicons", config = true },
	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = setup("plugins.diffview", "diffview"),
	},
	{ "kevinhwang91/nvim-hlslens" },
	{
		"petertriho/nvim-scrollbar",
		dependencies =  { "kevinhwang91/nvim-hlslens" },
		config = setup("plugins.scrollbar", "scrollbar"),
	},
	{ "ggandor/leap.nvim", config = setup("plugins.leap", "leap"), event="BufEnter" },
	{
		"nvim-treesitter/nvim-treesitter",
		config = setup("plugins.treesitter", "nvim-treesitter"),
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies =  {"nvim-treesitter/nvim-treesitter"},
		config = setup("plugins.treesitter-context"),
	},
	{ "karb94/neoscroll.nvim", dependencies= { "nvim-treesitter/nvim-treesitter-context" } , config = setup("plugins.neoscroll", "neoscroll") },
	{ "lambdalisue/glyph-palette.vim" },
	{ "mattn/emmet-vim", ft = { "html", "vue", "javascript", "javascriptreact", "typescriptreact" } },
	{ "AndrewRadev/tagalong.vim" },
	{ "alvan/vim-closetag" },
	{ "vim-test/vim-test", config = setup("plugins.vim-test") },
	{ "simrat39/rust-tools.nvim" },
})
