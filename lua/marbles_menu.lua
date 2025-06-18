-- ReadMe - marbles_menu.lua v1.0.1
-- License: MIT
-- Concept and programming by LBS with AI assistance. 
-- Editing and testing done in Neovim.
-- Project URL: https://github.com/artstisen/marbles.nvim 

-- marbles_menu.lua
local M = {}

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
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

  local cursor = 1
  local scroll_offset = 0
  local max_display = 10

  local width = 45
  local base_height = #menu_items + 1  -- 1 for title + visible items

  -- === Dynamically include footer height ===
  local footer_text = ""
  if footer_fn then
    footer_text = type(footer_fn) == "function" and footer_fn() or tostring(footer_fn)
  end
  local has_footer = footer_text and footer_text:match("%S")
  local height = base_height + (has_footer and 2 or 0)

  local row = (vim.o.lines - height) / 2
  local col = (vim.o.columns - width) / 2

  local float_bg = get_hl_color("Normal", "bg") or "#1e1e1e"
  local float_fg = get_hl_color("Normal", "fg") or "#ffffff"
  local border_fg = get_hl_color("Normal", "fg") or "#808080"

  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = float_bg, fg = float_fg })
  vim.api.nvim_set_hl(0, 'FloatBorder', { fg = border_fg, bg = float_bg })
  vim.api.nvim_set_hl(0, 'UtilMenuSelected', { bg = border_fg, fg = float_bg, bold = true })

  local function build_lines()
    local lines = { title }

    local total = #menu_items
    local view_start = scroll_offset + 1
    local view_end = math.min(total, scroll_offset + max_display)

    for i = view_start, view_end do
      local prefix = (i == cursor) and "> " or "  "
      table.insert(lines, prefix .. menu_items[i].label)
    end

    if has_footer then
      table.insert(lines, "")
      table.insert(lines, footer_text)
    end

    return lines
  end

  local function refresh()
    local lines = build_lines()
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

    local total = #menu_items
    local view_start = scroll_offset + 1
    local view_end = math.min(total, scroll_offset + max_display)

    if cursor >= view_start and cursor <= view_end then
      local hl_line = (cursor - view_start) + 2
      vim.api.nvim_buf_add_highlight(buf, -1, 'UtilMenuSelected', hl_line - 1, 0, -1)
    end

    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end

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

  vim.keymap.set('n', 'j', function()
    local total = #menu_items
    if total == 0 then return end

    cursor = cursor + 1
    if cursor > total then
      cursor = 1
      scroll_offset = 0
    elseif cursor > scroll_offset + max_display then
      scroll_offset = scroll_offset + 1
    end

    refresh()
  end, opts_keymap)

  vim.keymap.set('n', 'k', function()
    local total = #menu_items
    if total == 0 then return end

    cursor = cursor - 1
    if cursor < 1 then
      cursor = total
      scroll_offset = math.max(0, total - max_display)
    elseif cursor <= scroll_offset then
      scroll_offset = scroll_offset - 1
    end

    refresh()
  end, opts_keymap)

  vim.keymap.set('n', 'l', function()
    if cursor >= 1 and cursor <= #menu_items then
      close()
      menu_items[cursor].action()
    end
  end, opts_keymap)

  vim.keymap.set('n', '<CR>', function()
    if cursor >= 1 and cursor <= #menu_items then
      close()
      menu_items[cursor].action()
    end
  end, opts_keymap)

  vim.keymap.set('n', 'q', close, opts_keymap)
  vim.keymap.set('n', '<Esc>', close, opts_keymap)

  refresh()
end

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

