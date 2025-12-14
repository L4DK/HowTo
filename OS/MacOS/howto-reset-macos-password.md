# How to Reset a Forgotten macOS Password (Recovery Mode)

Titel: Reset a User Password on macOS Using Recovery Mode  
Created: 2025‑12‑14  
Author: Michael Landbo  
Github: https://www.github.com/L4DK

<br>

## Overview

This guide explains how to reset a forgotten macOS user password using **Recovery Mode**, the modern and Apple‑supported method.  
Unlike Single‑User Mode (which is removed on newer systems), Recovery Mode works on:
  
  - **Intel Macs**  
  - **Apple Silicon (M1/M2/M3) Macs**  
  - **Systems with Secure Boot enabled**

This method does **not** delete files, accounts, or system settings.

  Use this method when:
    - **You forgot your macOS account password**  
    - **You cannot log in to your admin account**  
    - **Single‑User Mode is unavailable**  
    - **You need to reset another user’s password**  
    - **You want an Apple‑approved recovery method**

<br>

## Step‑by‑Step Instructions

### 1. Boot into Recovery Mode

  **On Intel Macs:**  
    Restart your Mac and hold <kbd>⌘</kbd> + <kbd>R</kbd>
  
  **On Apple Silicon (M1/M2/M3):**
    1. Shut down the Mac completely  
    2. Press and **hold** the power button  
    3. Release when you see **“Loading startup options…”**  
    4. Select **Options → Continue**

<br>

### 2. Open Terminal

  In the top menu bar, select:
  
  **Utilities → Terminal**
  
  This opens a root‑level terminal inside Recovery Mode.

<br>

### 3. Launch the Password Reset Tool

  Run the built‑in macOS password reset utility:
    
    ```bash
    resetpassword
    ```
  
  This opens a graphical interface.

<br>

### 4. Select the User Account

  Choose the account you want to reset.
  
  If FileVault is enabled, you may need to unlock the disk first.

<br>

### 5. Enter a New Password

  Set a new password and confirm it.  
  You can also add a password hint if needed.

<br>

### 6. Restart the Mac

  Close the tool and restart:
  
  ```bash
  reboot
  ```
  
  You can now log in with the new password.

<br>

## Bonus Information

### Works on All Modern Macs
  Unlike Single‑User Mode, this method works on:
    - macOS Big Sur and newer  
    - Apple Silicon Macs  
    - Systems with Secure Boot  

### Does Not Affect Data
  Resetting a password **does not** delete:
    - Files  
    - Applications  
    - User settings  
    - Other accounts  

### FileVault Considerations
  If FileVault is enabled:
    - You must unlock the disk first  
    - You may need an existing admin password or recovery key  

<br>

## Compatibility Notes

### Supported:
  - Intel Macs  
  - Apple Silicon Macs  
  - macOS Big Sur and newer  
  - Systems with Secure Boot enabled  

### Not Supported:
  - Systems with corrupted Recovery partitions  
  - Macs with firmware passwords enabled (unless you know the password)  
  - Enterprise‑managed Macs with MDM restrictions  

<br>

## Troubleshooting

### The user does not appear in the list
  Possible causes:
    - FileVault is enabled  
    - The disk is locked  
    - The system is using a network or mobile account  

### “No administrator found”
  This can happen if:
    - The admin account was deleted  
    - The system directory is corrupted  

### Terminal says “command not found”
  Make sure you typed:
  
  ```
  resetpassword
  ```

(no spaces, no uppercase letters)

### FileVault won’t unlock
  You may need:
    - The recovery key  
    - Another admin password  
    - iCloud unlock (if enabled)

<br>

## FAQ

### Does this delete any of my files?
No.  
All existing user accounts, home folders, and personal data remain intact.

### Can I reset passwords after creating the new admin?
Yes.  
Once logged in with the new administrator account, go to  
**System Settings → Users & Groups** to reset passwords for any user.

### Can I remove the new admin account later?
Yes.  
After you regain access and finish your recovery tasks, you can safely delete the temporary admin account.

### Does this method work on Apple Silicon (M1/M2/M3)?
Yes — this is the recommended method for Apple Silicon Macs.

<br>

## Security Notes

- This method should only be used on systems you own or are authorized to maintain.  
- Recovery Mode bypasses normal login security.  
- Never share your recovery key or admin credentials.  
- Enterprise‑managed Macs may block password resets.  

<br>

## Final Notes

This guide provides a safe, modern, and Apple‑approved way to reset a forgotten macOS password.  
It works on all current Macs and is the recommended method when Single‑User Mode is unavailable.
