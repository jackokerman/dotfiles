require("render-markdown").setup({
  code = {
    language_icon = false,
  },
  html = {
    enabled = false,
  },
  latex = {
    enabled = false,
  },
  yaml = {
    enabled = false,
  },
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles-markdown", { clear = true }),
  pattern = "markdown",
  callback = function(event)
    vim.keymap.set("n", "<leader>mt", function()
      require("render-markdown").buf_toggle()
    end, { buffer = event.buf, desc = "Toggle Markdown rendering", silent = true })
  end,
})
