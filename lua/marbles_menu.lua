-- ReadMe - marbles_menu.lua v1.0.0
-- License: MIT
-- Concept and programming by LBS with AI assistance. 
-- Editing and testing done in Neovim.
-- Project URL: https://github.com/artstisen/marbles.nvim 

-- marbles_menu.lua
local M = {}

-- Utility: Get highlight color from colorscheme
local function get_hl_color(group, attr)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
  if ok and hl and hl[attr] then
    return string.format("#%06x", hl[attr])
  end
end

function M.open_menu(opts)
  opts = opts or {}
  local menu_items = opts.menu_items or {}
  local title = opts.title or "# Menu (j/k/l/Enter/Esc)"
  local footer_fn = opts.footer

  local buf = vim.api.nvim_create_buf(false, true)
  local cursor = 2 -- line 1 = title, so first item starts at line 2

  local width = 45
  local height = #menu_items + 3 -- title + items + footer
  local row = (vim.o.lines - height) / 2
  local col = (vim.o.columns - width) / 2

  -- Fetch colors or fallback
  local float_bg = get_hl_color("Normal", "bg") or "#1e1e1e"
  local float_fg = get_hl_color("Normal", "fg") or "#ffffff"
  local border_fg = get_hl_color("Normal", "fg") or "#808080"

  -- Set highlight groups
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = float_bg, fg = float_fg })
  vim.api.nvim_set_hl(0, 'FloatBorder', { fg = border_fg, bg = float_bg })
  vim.api.nvim_set_hl(0, 'UtilMenuSelected', { bg = border_fg, fg = float_bg, bold = true })

  -- Helper to build lines for buffer
  local function build_lines()
    local lines = { title }
    for i, item in ipairs(menu_items) do
      local line = (i + 1 == cursor) and "> " .. item.label or "  " .. item.label
      table.insert(lines, line)
    end
    -- Optional footer
    if footer_fn then
      local footer_line = type(footer_fn) == "function" and footer_fn() or tostring(footer_fn)
      table.insert(lines, "")
      table.insert(lines, footer_line)
    end
    return lines
  end

  -- Render menu content
  local function refresh()
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
    local lines = build_lines()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

    -- Only highlight valid menu item line:
    if cursor >= 2 and cursor <= (#menu_items + 1) then
      vim.api.nvim_buf_add_highlight(buf, -1, 'UtilMenuSelected', cursor - 1, 0, -1)
    end

    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end

  refresh()

  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    noautocmd = true,
  })

  vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:NormalFloat,FloatBorder:FloatBorder')

  local opts_keymap = { buffer = buf, nowait = true, silent = true }

  local function close()
    vim.api.nvim_win_close(win, true)
  end

  -- Wrap-around navigation
  vim.keymap.set('n', 'j', function()
    if cursor >= (#menu_items + 1) then
      cursor = 2
    else
      cursor = cursor + 1
    end
    refresh()
  end, opts_keymap)

  vim.keymap.set('n', 'k', function()
    if cursor <= 2 then
      cursor = (#menu_items + 1)
    else
      cursor = cursor - 1
    end
    refresh()
  end, opts_keymap)

  vim.keymap.set('n', 'l', function()
    local index = cursor - 1
    if index >= 1 and index <= #menu_items then
      close()
      menu_items[index].action()
    end
  end, opts_keymap)

  vim.keymap.set('n', '<CR>', function()
    local index = cursor - 1
    if index >= 1 and index <= #menu_items then
      close()
      menu_items[index].action()
    end
  end, opts_keymap)

  vim.keymap.set('n', 'q', close, opts_keymap)
  vim.keymap.set('n', '<Esc>', close, opts_keymap)
end

-- Optional default command if you want:
vim.api.nvim_create_user_command("Util", function()
  M.open_menu({
    title = "# Util Menu",
    menu_items = {
      { label = "Example item 1", action = function() print("Item 1 selected") end },
      { label = "Example item 2", action = function() print("Item 2 selected") end },
    },
    footer = "Footer example here.",
  })
end, {})

return M
