local function visual_range()
  local start = vim.api.nvim_buf_get_mark(0, "<")
  local finish = vim.api.nvim_buf_get_mark(0, ">")

  if start[1] == 0 or finish[1] == 0 then
    return nil
  end

  return {
    start = { start[1], start[2] },
    ["end"] = { finish[1], finish[2] + 1 },
  }
end

local function command_range(command)
  if command.range == 0 then
    return nil
  end

  local range = visual_range()
  if range ~= nil then
    return range
  end

  local last_line = vim.api.nvim_buf_get_lines(0, command.line2 - 1, command.line2, false)[1] or ""
  return {
    start = { command.line1, 0 },
    ["end"] = { command.line2, #last_line },
  }
end

local function format(command)
  require("conform").format({
    async = false,
    lsp_format = "never",
    range = command and command_range(command) or nil,
  })
end

require("conform").setup({
  default_format_opts = {
    lsp_format = "never",
    stop_after_first = true,
  },
  formatters_by_ft = {
    css = { "prettier" },
    html = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    markdown = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    yaml = { "prettier" },
  },
})

vim.api.nvim_create_user_command("Format", format, {
  desc = "Format the current buffer or range",
  range = true,
})

return {
  format = format,
}
