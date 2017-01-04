> Thanks to [![Sponsor](https://cdnwp.crypteron.com/wp-content/themes/crypteron/includes/img/LogoMenuIcon.png)  Crypteron](http://www.crypteron.com) for sponsoring this side-project! If you're a developer building cloud / server applications and are concerned about compliance and data security, check out [Crypteron](http://www.crypteron.com)'s Data Security Platform.

# Who should use this?

You want
- the convenience of cloud storage solutions like Dropbox, Google Drive, OneDrive etc 
- to keep your private information, well, private even when the files are kept with someone else
- simplicity ... just double click a file, edit/view it and be done with it. You find the default GPG workflow to be tedious and error prone.

# End User Experience
- Double click an encrypted file to work with it (e.g. double clicking `proposal.docx.gpg` directly opens it in Word) 

# What does it do?
It keeps your files encrypted while allowing seamless access to read/edit/update those files. Opening any encrypted file (e.g. `proposal.docx.gpg`) is a just a simple double-click in Windows Explorer. If you edit your document, those changes go back into the encrypted file without any additional effort. Note that you need to close the application used for editing the file (e.g. Microsoft Excel) with before these scripts proceed to check for changes and re-encrypting the file(s).

On a technical level, it's a bunch of PowerShell scripts that glue OpenPGP/GnuGP, Windows Explorer, Windows Applications and Cloud Storage Tools (e.g. Dropbox, OneDrive etc). If you are a developer and want to improve, please feel to collaborate via GitHub pull requests.

## Installation steps

Installation takes seconds but encrypting all your files may take several minutes/hours depending on how many files you've got. 

> WARNING 1: It is recommended that you create a backup of your files before proceeding - in case you mess things up.

> WARNING 2: Be sure to backup your certificate/keypair created below. Without them even you will NOT be able to decrypt your own encrypted file. Your files will be effectively lost forever. Example: Keep a copy on a USB stick and put the stick inside a safe

1. Install [Gpg4Win](https://www.gpg4win.org/download.html). Basically get the `.exe` file and run it. Need more help? [Look here](https://www.gpg4win.org/doc/en/gpg4win-compendium_11.html).
2. Create your OpenPGP certificate/keypair. Try the Kleopatra tool installed by Gpg4Win. [Details here](https://www.gpg4win.org/doc/en/gpg4win-compendium_12.html) 
3. Clone/download this repository of files
4. Using Notepad, edit the top of `CipherDocs.ps1` and `EncryptFiles.ps1` and replace the email inside `$recipient = "sid@crypteron.com"` to your OpenPGP/GnuPG keypair ID/name from the above step.
5. Install these scripts by double clicking the `Install.bat` file.
6. Encrypt your files by double clicking the `EncryptFiles.bat` file. You will be asked to select a folder and all files in there (including subfolders) will be encrypted. Specifically, all files NOT ending in `.gpg` will be considered for encryption and we use AES 256 for all our encryption. Optionally you can delete the leftover original unencrypted files after they have been encrypted. It's recommended to delete the unencrypted leftovers for a clean workflow (as long as you have a 'just in case' backup elsewhere).

You're set up! All files in the folder of your choice (e.g. your `Dropbox` folder) are now encrypted.

## How it works
During normal usage we automatically do a few things behind the scenes. We
   - decrypt the file via GPG into a temporary local folder
   - open the file with the registered application (e.g. `doc` files will be opened by Microsoft Word, `pdf` files with your PDF application etc.)
   - If you edit the file (new edit timestamp or file contents change) then we will re-encrypt the modified temporary file via GPG and move it back into your original cloud folder (overwriting the older encrypted version).

# Limitations

1. This may be obvious or subtle based on your background but other devices sync'd with your onedrive/dropbox/google drive won't be able to open the encrypted files without GPG (or these wrapper scripts) and your private GPG key installed on it. 
2. **Currently assumes a single authorized person for each file**. Files are  encrypted/re-encrypted for a single GPG key like `you@email.com`. So if you want to share that private financial spreadsheet with someone like `spouse@email.com` - that's currently not supported. To clarify, they may get the encrypted file via email or by sharing via the cloud service itself - but they won't be able to decrypt it and see anything inside.
3. No continuous file system monitoring to detect new unencrypted files and encrypting them. Currently you must run the encryption script from the `Installation steps` stage periodically. Explore via something like `$monitor = New-Object System.IO.FileSystemWatcher` in the future ?
4. Windows based: Although gpg and powershell are cross platform, the explorer based integration makes them Windows specific. Eventually we want to expand these powershell scripts to integrate with Finder (Mac) and Nautilus (Linux) too.

# Comments

- We're using `.bat` files to launch `powershell` scripts because windows, by default allows double-click-to-run on those. Yes, batch files suck for programming but PowerShell is incredible.
- Although you may delete the unencrypted files, you should realise these were previously uploaded to your cloud storage provider. As such, you should check with your storage provider on their data retention policies.
