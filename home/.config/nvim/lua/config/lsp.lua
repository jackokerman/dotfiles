vim.diagnostic.config({
  float = { border = "rounded" },
  severity_sort = true,
})

vim.lsp.config("eslint", {
  settings = {
    codeActionOnSave = {
      enable = false,
      mode = "all",
    },
    format = false,
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("dotfiles-lsp-attach", { clear = true }),
  callback = function(event)
    local buffer = event.buf
    local options = { buffer = buffer, silent = true }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", options, { desc = "Go to definition" }))
    vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", options, { desc = "Go to references" }))
    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", options, { desc = "Hover" }))
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", options, { desc = "Rename symbol" }))
    vim.keymap.set(
      { "n", "v" },
      "<leader>ca",
      vim.lsp.buf.code_action,
      vim.tbl_extend("force", options, { desc = "Code actions" })
    )
  end,
})

vim.lsp.enable({
  "ts_ls",
  "eslint",
})
