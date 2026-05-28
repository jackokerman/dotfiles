local snacks = require("snacks")

snacks.setup({
  picker = {
    enabled = true,
    ui_select = true,
    sources = {
      explorer = {
        hidden = true,
      },
      files = {
        hidden = true,
      },
      grep = {
        hidden = true,
      },
    },
  },
  explorer = {
    enabled = true,
    replace_netrw = true,
  },
})

vim.keymap.set("n", "<leader>e", function()
  snacks.explorer()
end, { desc = "File explorer", silent = true })

vim.keymap.set("n", "<C-p>", function()
  snacks.picker.files()
end, { desc = "Find files", silent = true })

vim.keymap.set("n", "<leader>/", function()
  snacks.picker.grep()
end, { desc = "Grep files", silent = true })

vim.keymap.set("n", "<leader>,", function()
  snacks.picker.buffers()
end, { desc = "Switch buffers", silent = true })

vim.keymap.set("n", "<leader>r", function()
  snacks.picker.recent()
end, { desc = "Recent files", silent = true })

vim.keymap.set("n", "<leader>sk", function()
  snacks.picker.keymaps()
end, { desc = "Search keymaps", silent = true })

vim.keymap.set("n", "<leader>sd", function()
  snacks.picker.diagnostics()
end, { desc = "Search diagnostics", silent = true })
