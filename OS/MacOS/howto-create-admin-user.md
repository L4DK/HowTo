# How to Create an Admin User in macOS (Single‑User Mode)

Titel: How to Create a User Account with Admin Permissions in macOS  
Created: 2025‑12‑14  
Author: Michael Landbo  
Github: https://www.github.com/L4DK

<br>

## Overview

This guide explains how to create a new local administrator account on macOS by using Single‑User Mode and removing the `.AppleSetupDone` file.  
This forces macOS to run the Setup Assistant again, allowing you to create a fresh admin user.

This method is useful when:
- **You lost access to the admin account**
- **The admin password is unknown**
- **The system has no admin users available**

<br>

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

<br>

## Delete AppleSetupDone and Create a New Administrative Account

Removing the `.AppleSetupDone` file forces macOS to run the **Welcome / Setup Assistant** again.  
This allows you to create a brand‑new administrator account.

You can then:
- Log in with the new admin user  
- Reset passwords for existing accounts  
- Copy files from old accounts  

<br>

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

<br>

## Bonus Information

### What `.AppleSetupDone` Actually Does
macOS places a hidden file at:
```
/var/db/.AppleSetupDone
```
This file tells the system:
> “The initial setup has already been completed.”

Deleting it makes macOS behave as if it is a brand‑new machine.

### This method does NOT:
- Delete existing users  
- Remove files  
- Reset system settings  
- Erase the disk  

It only resets the **setup state**, not the data.

<br>

## Compatibility Notes

### Works on:
- Older Intel‑based Macs  
- macOS versions that still support Single‑User Mode  
- Systems without a T2 security chip  
- Systems where Startup Security Utility allows reduced security  

### Does NOT work on:
- Newer macOS versions where Single‑User Mode is removed  
- Apple Silicon (M1/M2/M3) Macs  
- Macs with Secure Boot locked to “Full Security”  
- Systems where the user cannot access Recovery Mode  

<br>

## Alternative Method: Using Recovery Mode (Modern macOS)

If Single‑User Mode is unavailable, you can use **Recovery Mode**:

1. Restart your Mac and hold <kbd>⌘</kbd> + <kbd>R</kbd>  
2. Open **Terminal** from the Utilities menu  
3. Run:
   ```
   resetpassword
   ```
4. Use the graphical tool to reset any user’s password  
5. Reboot normally  

This is the Apple‑approved method for newer systems.

<br>

## Troubleshooting

### The system says the disk is read‑only
Run:
```bash
/sbin/mount -uw /
```

### `.AppleSetupDone` cannot be deleted
Possible causes:
- SIP (System Integrity Protection) is enabled  
- The system is too new to support Single‑User Mode  
- The disk is not mounted as writable  

### Setup Assistant does not appear after reboot
Check if the file still exists:
```bash
ls -la /var/db/.AppleSetupDone
```

If it reappears automatically, the system may be enforcing security policies.

<br>

## FAQ

### Does this delete any of my files?
No.  
All existing user accounts, home folders, and personal data remain untouched.

### Can I reset passwords after creating the new admin?
Yes.  
Once logged in with the new administrator account, go to  
**System Settings → Users & Groups** to reset passwords for any user.

### Can I remove the new admin account later?
Yes.  
After you regain access and finish your recovery tasks, you can safely delete the temporary admin account.

### Does this method work on Apple Silicon (M1/M2/M3)?
Generally no.  
Apple Silicon Macs no longer support Single‑User Mode, and security restrictions prevent this method from working.


<br>

## Security Notes

- This method should only be used on systems you own or are authorized to maintain.  
- Never use this technique on devices without explicit permission.  
- Avoid typing passwords in plain text in terminal environments.  
- Newer macOS versions intentionally block this method for security reasons.  

<br>

## Final Notes

This guide provides a reliable way to regain administrative access on older macOS systems using Single‑User Mode.  
For modern systems, Recovery Mode is the recommended and supported approach.

