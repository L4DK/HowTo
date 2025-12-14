# How to Create an Admin User in macOS (Single‑User Mode)

Titel: How to Create a User Account with Admin Permissions in macOS  
Created: 2025‑12‑14  
Author: Michael Landbo  
Github: https://www.github.com/L4DK

---

## Overview

This guide explains how to create a new local administrator account on macOS by using Single‑User Mode and removing the `.AppleSetupDone` file.  
This forces macOS to run the Setup Assistant again, allowing you to create a fresh admin user.

This method is useful when:
- **You lost access to the admin account**
- **The admin password is unknown**
- **The system has no admin users available**

---

## Pre‑Check / Fixing Steps

1. Restart your MacBook in **Single‑User Mode** by holding <kbd>⌘</kbd> + <kbd>S</kbd> during boot until you see the terminal.

2. **Check filesystem integrity (optional but recommended):**
   ```bash
   /sbin/fsck -fy
   ```

3. **Mount the root filesystem with write access:**
   ```bash
   /sbin/mount -wu /
   ```

4. **Fix root permissions:**
   ```bash
   /bin/chmod 1775 /
   ```

5. **Commit filesystem changes:**
   ```bash
   /bin/sync
   ```

---

## Delete AppleSetupDone and Create a New Administrative Account

Removing the `.AppleSetupDone` file forces macOS to run the **Welcome / Setup Assistant** again.  
This allows you to create a brand‑new administrator account.

You can then:
- Log in with the new admin user  
- Reset passwords for existing accounts  
- Copy files from old accounts  

---

## Workaround to Enable Creation of a Local Sysadmin User

6. **Remove the setup completion flag:**
   ```bash
   rm /var/db/.AppleSetupDone
   ```

7. **Reboot:**
   ```bash
   reboot
   ```

8. **Done.**  
   macOS will now start the Setup Assistant, where you can create a new administrator account.
