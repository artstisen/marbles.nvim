# 🔒 marbles.nvim
## Easy file encryption for [Neovim](https://neovim.io/)
**marbles.nvim** can be used both with commands or with the built-in menu to encrypt and decrypt the contents of your files.

![marbles-nvim1](https://github.com/artstisen/marbles.nvim/blob/main/marbles-nvim1.gif)

## Summary
**marbles.nvim** makes it easy to encrypt and decrypt the contents of files in Neovim on-the-fly. The script limits itself to a specific file type so it does not interfere with your normal workflow. The script can automatically decrypt encrypted files if a key is set beforehand. Files that are opened and decrypted are set as readonly so you can pick the information you need. With the toggle command you can unlock the file and change/add content before encrypting and saving the file again. Shada and swap files are disabled for that file type so you don't inadvertently store sensitive data in nvims temp files. When creating an encryption key, you are asked twice to ensure that the key is entered correctly. If no encryption key is specified, you can manually decrypt the file (see Commands), where the script will ask for your encryption key.

**If you load and decrypt a file without having cached a key in memory, your key is requested. However, if your key is already set, the file is automatically decrypted.**

![marbles-nvim2](https://github.com/artstisen/marbles.nvim/blob/main/marbles-nvim2.gif)

### Background
[Vim](https://www.vim.org/) has built-in encryption, but Neovim does not. This was omitted as a deliberate choice. The implementation in Vim is very basic and I wanted to stay in Neovim as well.

I've previously made a couple of apps for taking notes with encryption, both terminal (cross-platform) and OS-specific:
* [https://github.com/artstisen/marbles](https://github.com/artstisen/marbles) 
* [https://github.com/artstisen/AHOY](https://github.com/artstisen/AHOY) 
  
However, since I now do all my work in Neovim, I would like to have the option to encrypt certain files instead of switching programs or changing my previous programs to have vim-style navigation etc. So I made this simple plugin to enable quick and easy encryption of file types of my own choice.

### Specifications
* **Encryption:** AES-256 with BASE64 encoding.
* **File type:** `.marbles` - This plugin will only target files with a _.marbles_ extension. This was done on purpose to separate normal workflow in nvim from files containing sensitive information. Feel free to change file extension or modify the script in any way you like.
* **Security:** Shada and swapfiles are disabled for .marbles files but not for other file types. This will prevent sensitive information from being stored in temporary files that are not encrypted.
* **Please note:** .marbles files are rendered as markdown files. Just remove this option `vim.bo.filetype = "markdown"` if you want plain text.

### Requirements and installation
* Written and tested for Neovim v0.11, but should work on older versions from v0.8 and up.
* Requires [openssl](https://openssl-library.org/) to encrypt/decrypt file contents.
1. Place the marbles.lua and marbles_menu.lua files in your lua folder and instantiate the plugin from your init file with `require("marbles").setup()`
2. This plugin uses openssl: [https://github.com/openssl/openssl/wiki/Binaries/](https://github.com/openssl/openssl/wiki/Binaries) Install openssl and change the path in the script `run_openssl` method to reference the openssl executable on your system.

### Commands
* `:EncryptFile` - Encrypt current .marblesfile using password. Will use cached password if available and if not prompt the user to enter a new password twice. Remember to save your file afterwards.
* `:DecryptFile` - Decrypt current .marblesfile using password. Will use cached password if available and auto-decrypt files when opening them. Auto decrypted files will open in readonly mode and modifieable set to false. Use ToggleReadonly.
* `:EncryptAndSaveFile` - Encrypt and write the file.
* `:CreateDefaultMarbles` - Create a default.marbles file.
* `:LoadDefaultMarbles` - Load the default.marbles file and decrypt it.
* `:CreateMarblesFile` - Create a .marbles file and prompt for a file name.
* `:SetEncryptionPassword` - Set and confirm new in-memory password. Can be set at the start to enable auto decryption when opening .marblesfiles. Or before encryption if a new password is needed.
* `:ClearEncryptionPassword` - Clear password from memory.
* `:ToggleReadonly` - Toggle between writable and readonly modes.

> TIP: Change the commands as you like and bind them to the keys you want.

### Disclaimer
Please note: If you forget your encryption key (password), it will not be possible to recover your encrypted data. I cannot be held liable for any data lost as a result of using this plugin. See [software license](https://github.com/artstisen/marbles.nvim/blob/main/LICENSE) for further information.
