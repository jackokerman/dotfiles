vim.pack.add({
  { src = "https://github.com/bluz71/vim-nightfly-colors", name = "nightfly" },
  { src = "https://github.com/neovim/nvim-lspconfig", name = "nvim-lspconfig" },
  { src = "https://github.com/stevearc/conform.nvim", name = "conform.nvim" },
})

vim.cmd("colorscheme nightfly")
