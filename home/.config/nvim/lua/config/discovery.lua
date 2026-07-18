local which_key = require("which-key")

which_key.setup({
  icons = {
    mappings = false,
  },
})

which_key.add({
  { "<leader>c", group = "code" },
  { "<leader>s", group = "search" },
})

vim.keymap.set("n", "<leader>?", function()
  local cheatsheet = vim.fn.stdpath("config") .. "/CHEATSHEET.md"

  vim.cmd("botright 20split " .. vim.fn.fnameescape(cheatsheet))
  vim.bo.buflisted = false
  vim.bo.modifiable = false
  vim.bo.swapfile = false
  vim.wo.wrap = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", {
    buffer = true,
    desc = "Close cheat sheet",
    silent = true,
  })
end, { desc = "Vim cheat sheet", silent = true })
