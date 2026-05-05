vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic", silent = true })

vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic", silent = true })

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostics", silent = true })
vim.keymap.set("n", "<leader>f", "<cmd>Format<cr>", { desc = "Format buffer", silent = true })
vim.keymap.set("x", "<leader>f", ":<C-u>Format<cr>", { desc = "Format selection", silent = true })
