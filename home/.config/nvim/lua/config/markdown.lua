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

local function blend(foreground, background, alpha)
  local function channel(color, offset)
    return tonumber(color:sub(offset, offset + 1), 16)
  end

  local function mixed(offset)
    local foreground_channel = channel(foreground, offset)
    local background_channel = channel(background, offset)
    return math.floor(alpha * foreground_channel + (1 - alpha) * background_channel + 0.5)
  end

  return string.format("#%02x%02x%02x", mixed(2), mixed(4), mixed(6))
end

local function apply_nightfly_theme()
  local palette = require("nightfly").palette
  local heading_colors = {
    palette.blue,
    palette.tan,
    palette.green,
    palette.emerald,
    palette.violet,
    palette.purple,
  }

  for level, foreground in ipairs(heading_colors) do
    local background = blend(foreground, palette.bg, 0.1)
    vim.api.nvim_set_hl(0, "@markup.heading." .. level .. ".markdown", {
      fg = foreground,
      bg = background,
      bold = true,
    })
    vim.api.nvim_set_hl(0, "RenderMarkdownH" .. level .. "Bg", { bg = background })
  end

  vim.api.nvim_set_hl(0, "RenderMarkdownBullet", { fg = palette.orange })
  vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = palette.black_blue })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { link = "@markup.raw.markdown_inline" })
  vim.api.nvim_set_hl(0, "RenderMarkdownDash", { fg = palette.orange })
  vim.api.nvim_set_hl(0, "RenderMarkdownTableHead", { fg = palette.watermelon })
  vim.api.nvim_set_hl(0, "RenderMarkdownTableRow", { fg = palette.orange })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("dotfiles-markdown-theme", { clear = true }),
  pattern = "nightfly",
  callback = apply_nightfly_theme,
})

apply_nightfly_theme()

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles-markdown", { clear = true }),
  pattern = "markdown",
  callback = function(event)
    vim.keymap.set("n", "<leader>mt", function()
      require("render-markdown").buf_toggle()
    end, { buffer = event.buf, desc = "Toggle Markdown rendering", silent = true })
  end,
})
