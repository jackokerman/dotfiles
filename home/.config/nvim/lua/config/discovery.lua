local which_key = require("which-key")

which_key.setup({
  icons = {
    mappings = false,
  },
})

which_key.add({
  { "<leader>c", group = "code" },
  { "<leader>h", group = "help" },
  { "<leader>s", group = "search" },
})

vim.keymap.set("n", "<leader>?", function()
  which_key.show({ global = false })
end, { desc = "Buffer local keymaps", silent = true })

vim.keymap.set("n", "<leader>hc", function()
  local cheatsheet = vim.fn.stdpath("config") .. "/CHEATSHEET.md"
  local buffer = vim.fn.bufnr(cheatsheet)

  if buffer ~= -1 then
    local found = false

    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_buf(window) == buffer then
        vim.api.nvim_win_close(window, false)
        found = true
      end
    end

    if found then
      return
    end
  end

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
