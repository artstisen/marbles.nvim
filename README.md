# marbles.nvim
**Easy file encryption for Neovim**

## Summary
This Neovim plugin makes it easy to encrypt and decrypt the contents of files on-the-fly. The script limits itself to a specific file type so it does not interfere with your normal workflow. The script can automatically decrypt encrypted files if a key is set beforehand. Files that are opened and decrypted are set as readonly so you can pick the information you need. With the toggle command you can unlock the file and change/add content before encrypting and saving the file again. Shada and swap files are disabled for that file type so you don't inadvertently store sensitive data in nvims temp files. When creating an encryption key, you are asked twice to ensure that the key is entered correctly. If no encryption key is specified, you can manually decrypt the file (see Commands), where the script will ask for your encryption key.

## Background
Vim has built-in encryption, but Neovim does not. This was omitted as a deliberate choice. The implementation in Vim is very basic and I wanted to stay in Neovim as well.

I've previously made a couple of apps for taking notes with encryption, both terminal (cross-platform) and OS-specific:
* [https://github.com/artstisen/marbles](https://github.com/artstisen/marbles) 
* [https://github.com/artstisen/AHOY](https://github.com/artstisen/AHOY) 
  
However, since I now do all my work in Neovim, I would like to have the option to encrypt certain files instead of switching programs or changing my previous programs to have vim-style navigation etc. So I made this simple plugin to enable quick and easy encryption of file types of my own choice.

## Specifications
* **Encryption:** AES-256 with BASE64 encoding.
*  **File type:** .marbles - This plugin will only target files with a .marbles extension. This was done on purpose to separate normal workflow in nvim from files containing sensitive information. Feel free to change file extension or modify the script in any way you like.
* **Security:** Shada and swapfiles are disabled for .marbles files but not for other file types. This will prevent sensitive information from being stored in temporary files that are not encrypted.
* **Please note:** .marbles files are rendered as markdown files. Just remove this option (vim.bo.filetype = "markdown") if you want plain text.

## Installation
1. Place the marbles.lua file in your lua folder and instantiate the plugin from your init file with _require("marbles").setup()_
2. This plugin uses openssl: [https://openssl-library.org/](https://openssl-library.org/) Install openssl and change the path in this code to reference the openssl executable on your system.

## Commands
* **:EncryptFile** – Encrypt current .marblesfile using password. Will use cached password if available and if not prompt the user to enter a new password twice. Remember to save your file afterwards.
* **:DecryptFile** – Decrypt current .marblesfile using password. Will use cached password if available and auto-decrypt files when opening them. Auto decrypted files will open in readonly mode and modifieable set to false. Use ToggleReadonly.
* **:SetEncryptionPassword** – Set and confirm new in-memory password. Can be set at the start to enable auto decryption when opening .marblesfiles. Or before encryption if a new password is needed.
* **:ClearEncryptionPassword** – Clear password from memory.
* **:ToggleReadonly** – Toggle between writable and readonly modes.

Change the commands as you like and bind them to the keys you want.
