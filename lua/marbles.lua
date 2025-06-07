-- ReadMe - marbles.lua v1.0.4
-- License: MIT
-- Concept and programming by LBS with AI assistance. 
-- Editing and testing done in Neovim.
-- Project URL: https://github.com/artstisen/marbles.nvim 
-- Encryption: AES-256 with BASE64 encoding.
-- Security: Shada and swapfiles are disabled for .marbles files but not for
--           other file types. This will prevent sensitive information from being
--           stored in temporary files that are not encrypted.
-- File type: .marbles - This plugin will only target files with a .marbles extension.
--            This was done on purpose to separate normal workflow in nvim
--            from files containing sensitive information. Feel free to change
--            file extension or modify the script in any way you like.
-- Please note: .marbles files are rendered as markdown files. Just remove this
--              option (vim.bo.filetype = "markdown") if you want plain text.
--
-- Installation
-- Place the marbles.lua file in your lua folder and instantiate the plugin from your
-- init file with require("marbles").setup()
-- This plugin uses openssl: https://openssl-library.org/
-- Install openssl and change the path in this code to reference the
-- openssl executable on your system.
-- 
-- Commands
-- :EncryptFile – Encrypt current .marblesfile using password.
--                Will use cached password if available and if
--                not prompt the user to enter a new password twice.
--                Remember to save your file afterwards.
-- :DecryptFile – Decrypt current .marblesfile using password.
--                Will use cached password if available
--                and auto-decrypt files when opening them.
--                Auto decrypted files will open in readonly mode
--                and modifieable set to false. Use ToggleReadonly.
-- :SetEncryptionPassword – Set and confirm new in-memory password.
--                          Can be set at the start to enable auto
--                          decryption when opening .marblesfiles.
--                          Or before encryption if a new password
--                          is needed.
-- :CreateDefaultMarbles - Create a default.marbles file.
-- :LoadDefaultMarbles - Load the default.marbles file and decrypt it.
-- :CreateMarblesFile - Create a .marbles file and prompt for a file name.
-- :EncryptAndSaveFile - Encrypt and write the file.
-- :ClearEncryptionPassword – Clear password from memory.
-- :ToggleReadonly – Toggle between writable and readonly modes.

-- marbles.lua
local M = {}

-- In-memory password cache
local password_cache = nil

-- Prompt for password (hidden input)
local function prompt_password(prompt)
  local password = vim.fn.inputsecret(prompt .. ": ")
  if password == "" then
    print("Operation cancelled")
    return nil
  end
  return password
end

-- Confirm password twice
local function prompt_password_confirm()
  local pw1 = vim.fn.inputsecret("Enter encryption password: ")
  local pw2 = vim.fn.inputsecret("Confirm encryption password: ")
  if pw1 == "" or pw2 == "" then
    print("Operation cancelled.")
    return nil
  end
  if pw1 ~= pw2 then
    vim.notify("Passwords do not match. Please try again.", vim.log.levels.ERROR)
    return nil
  end
  return pw1
end

-- Check if file is .marbles
local function is_marbles_file()
  local filename = vim.fn.expand("%:t")
  return filename:match("%.marbles$")
end

-- Read buffer content
local function get_buffer_content()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

-- Set buffer content
local function set_buffer_content(str)
    vim.bo.readonly = false 
    vim.bo.modifiable = true 
  local lines = vim.split(str, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

-- OpenSSL interface
local function run_openssl(input, mode, password)
  local args = (mode == "encrypt")
    and { "enc", "-aes-256-cbc", "-salt", "-base64", "-pbkdf2", "-pass", "pass:" .. password }
    or  { "enc", "-d", "-aes-256-cbc", "-base64", "-pbkdf2", "-pass", "pass:" .. password }

  local result = vim.fn.system({ "C:\\Program Files\\OpenSSL-Win64\\bin\\openssl.exe", unpack(args) }, input)
  local success = vim.v.shell_error == 0
  return success, result
end

-- Core processing
local function process_buffer(mode)
  if not is_marbles_file() then
    print("Only .marbles files are supported.")
    return
  end

  local password = nil

  if mode == "encrypt" then
    if password_cache then
      password = password_cache
    else
      password = prompt_password_confirm()
      if password then
        password_cache = password
      end
    end
  elseif mode == "decrypt" then
    if password_cache then
      password = password_cache
    else
      password = prompt_password("Enter decryption password")
      if not password then return end
      password_cache = password
    end
  end

  if not password then return end

  local content = get_buffer_content()
  local success, result = run_openssl(content, mode, password)

  if success then
    set_buffer_content(result)
    vim.bo.readonly = true
    vim.bo.modifiable = false
    vim.notify("File " .. mode .. "ed successfully.")
  else
    password_cache = nil -- Remove cached key
    vim.notify(mode .. "ion failed:\n" .. result, vim.log.levels.ERROR)
  end
end

-- Try auto-decrypting on open if password is cached
local function try_auto_decrypt()
  if not is_marbles_file() or not password_cache then
    return
  end

  local content = get_buffer_content()
  local success, result = run_openssl(content, "decrypt", password_cache)

  if success then
    set_buffer_content(result)
    vim.bo.readonly = false
    vim.bo.modifiable = false
    vim.notify("File auto-decrypted using cached password.")
    vim.bo.readonly = true
    vim.bo.modifiable = false
  else
    vim.notify("Auto-decryption failed. Opening as is.", vim.log.levels.WARN)
  end
end

-- Exported helper
function M.is_password_cached()
  return password_cache ~= nil
end

function M.setup()
  vim.api.nvim_create_user_command("EncryptFile", function()
    vim.bo.readonly = false
    vim.bo.modifiable = true
    process_buffer("encrypt")
    vim.bo.readonly = false
    vim.bo.modifiable = false
  end, {})

  vim.api.nvim_create_user_command("DecryptFile", function()
    vim.bo.readonly = true
    vim.bo.modifiable = true
    process_buffer("decrypt")
    vim.bo.readonly = true
    vim.bo.modifiable = false
  end, {})

  vim.api.nvim_create_user_command("EncryptAndSaveFile", function()
    vim.bo.readonly = false
    vim.bo.modifiable = true
    process_buffer("encrypt")
    vim.bo.readonly = false
    vim.bo.modifiable = true
    vim.cmd("write")
    vim.notify("File encrypted and saved.")
    vim.bo.readonly = false
    vim.bo.modifiable = false
  end, {})

  vim.api.nvim_create_user_command("CreateDefaultMarbles", function()
    local path = vim.fn.getcwd() .. "/default.marbles"
    if vim.fn.filereadable(path) == 1 then
      vim.notify("default.marbles already exists.", vim.log.levels.WARN)
      return
    end
    vim.cmd("edit " .. path)
    vim.cmd("write")
    vim.notify("Created default.marbles.")
  end, {})

  vim.api.nvim_create_user_command("LoadDefaultMarbles", function()
    local path = vim.fn.getcwd() .. "/default.marbles"
    if vim.fn.filereadable(path) == 0 then
      vim.notify("default.marbles does not exist in current directory.", vim.log.levels.ERROR)
      return
    end
    if not password_cache then
      local pw = prompt_password("Enter decryption password")
      if not pw then return end
      password_cache = pw
    end
    vim.cmd("edit " .. path)
  end, {})

  vim.api.nvim_create_user_command("CreateMarblesFile", function()
    local filename = vim.fn.input("Enter new .marbles filename (without extension): ")
    if filename == "" then
      print("Operation cancelled.")
      return
    end
    local full_path = vim.fn.getcwd() .. "/" .. filename .. ".marbles"
    vim.cmd("edit " .. full_path)
    vim.cmd("write")
    vim.notify("Created " .. filename .. ".marbles")
  end, {})

  vim.api.nvim_create_user_command("ToggleReadonly", function()
    if not is_marbles_file() then
      print("Only .marbles files are supported.")
      return
    end
    if vim.bo.readonly or not vim.bo.modifiable then
      vim.bo.readonly = false
      vim.bo.modifiable = true
      vim.notify("File is now writable.")
    else
      vim.bo.readonly = true
      vim.bo.modifiable = false
      vim.notify("File is now readonly.")
    end
  end, {})

  vim.api.nvim_create_user_command("ClearEncryptionPassword", function()
    password_cache = nil
    vim.notify("Encryption password cleared from memory.")
  end, {})

  vim.api.nvim_create_user_command("SetEncryptionPassword", function()
    local pw = prompt_password_confirm()
    if pw then
      password_cache = pw
      vim.notify("Password set in memory.")
    end
  end, {})

  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    pattern = "*.marbles",
    callback = try_auto_decrypt,
  })

  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.marbles",
    callback = function()
      vim.opt_local.swapfile = false
      vim.opt_local.shadafile = "NONE"
      vim.bo.filetype = "markdown"
    end,
  })

  -- Menu integration
  local marbles_menu = require("marbles_menu")

  local marbles_menu_items = {
    { label = "Set key ....... :SetEncryptionPassword", action = function() vim.cmd("SetEncryptionPassword") end },
    { label = "Clear key ..... :ClearEncryptionPassword", action = function() vim.cmd("ClearEncryptionPassword") end },
    { label = "Decrypt ....... :DecryptFile", action = function() vim.cmd("DecryptFile") end },
    { label = "Encrypt ....... :EncryptFile", action = function() vim.cmd("EncryptFile") end },
    { label = "Encrypt+Save .. :EncryptAndSaveFile", action = function() vim.cmd("EncryptAndSaveFile") end },
    { label = "Toggle RO ..... :ToggleReadonly", action = function() vim.cmd("ToggleReadonly") end },
    { label = "Load default .. :LoadDefaultMarbles", action = function() vim.cmd("LoadDefaultMarbles") end },
    { label = "Create default  :CreateDefaultMarbles", action = function() vim.cmd("CreateDefaultMarbles") end },
    { label = "Create new .... :CreateMarblesFile", action = function() vim.cmd("CreateMarblesFile") end },
    { label = "Quit .......... :q!", action = function() vim.cmd("q!") end },
  }

  function M.open_marbles_menu()
    marbles_menu.open_menu({
      title = "# Marbles (j/k/l/Enter/Esc)",
      menu_items = marbles_menu_items,
      footer = function()
        return M.is_password_cached() and "Encryption password cached." or "No encryption password cached."
      end,
    })
  end

  vim.api.nvim_create_user_command("MarblesMenu", function() M.open_marbles_menu() end, {})
end

return M
