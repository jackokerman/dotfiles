local which_key = require("which-key")

which_key.setup({
  icons = {
    mappings = false,
  },
})

which_key.add({
  { "<leader>c", group = "code", mode = { "n", "v" } },
  { "<leader>s", group = "search" },
})

vim.keymap.set("n", "<leader>?", function()
  which_key.show({ global = false })
end, { desc = "Buffer local keymaps", silent = true })
