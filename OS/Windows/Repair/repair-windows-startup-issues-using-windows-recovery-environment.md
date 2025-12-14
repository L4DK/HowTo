# How to Repair Windows When It Won’t Boot (Using a Bootable USB Key)

Titel: Repair Windows Startup Issues Using Windows Recovery Environment  
Created: 2025‑12‑14  
Author: Michael Landbo  
Github: https://www.github.com/L4DK

<br>

## Overview

This guide explains how to repair Windows when the system cannot boot normally.  
Using a **bootable Windows USB installation media**, you can access the **Windows Recovery Environment (WinRE)** and perform repairs such as:

- Fixing corrupted boot files  
- Repairing the Master Boot Record (MBR)  
- Restoring system files  
- Running Startup Repair  
- Using System Restore  
- Accessing Command Prompt for advanced fixes  

<br>

This method is useful when:

- **Windows is stuck in a boot loop**
- **You see “Automatic Repair couldn’t repair your PC”**
- **The system freezes before login**
- **The bootloader is damaged**
- **You cannot access Safe Mode**

<br>

## Requirements

- A **bootable Windows USB key** (created with Microsoft’s Media Creation Tool)  
- A PC that can boot from USB  
- Basic understanding of BIOS/UEFI boot menus  

<br>

## Step 1 — Boot From the USB Key

1. Insert the Windows USB key into the computer.
2. Power on the PC.
3. Immediately press the boot menu key (varies by manufacturer):

  | Brand  | Boot Key                        |
  |--------|---------------------------------|
  | ASUS   | <kbd>F8</kbd>                   |
  | Acer   | <kbd>F12</kbd>                  |
  | Dell   | <kbd>F12</kbd>                  |
  | HP     | <kbd>Esc</kbd> or <kbd>F9</kbd> |
  | Lenovo | <kbd>F12</kbd>                  |
  | MSI    | <kbd>F11</kbd>                  |

4. Select the USB device from the boot menu.
5. Wait for the Windows installer to load.

<br>

## Step 2 — Open Windows Recovery Environment (WinRE)

When the Windows Setup screen appears:

1. Select your language and keyboard layout.
2. Click **Next**.
3. Click **Repair your computer** (bottom-left corner).

You are now inside **Windows Recovery Environment**.

<br>

## Step 3 — Use Startup Repair (Recommended First Step)

1. Go to **Troubleshoot**  
2. Select **Advanced options**  
3. Click **Startup Repair**

<br>

Windows will automatically scan and attempt to fix:

- Missing boot files  
- Damaged BCD entries  
- Boot loops  
- Corrupted system files  

If Startup Repair fails, continue to the next steps.

<br>

## Step 4 — Repair Boot Files Manually (Command Prompt)

Open:

**Troubleshoot → Advanced options → Command Prompt**

<br>

Run the following commands one by one:

### Rebuild the Boot Configuration Data (BCD)

```cmd
bootrec /rebuildbcd
```

<br>

### Repair the Master Boot Record (MBR)

```cmd
bootrec /fixmbr
```

<br>

### Repair boot sector

```cmd
bootrec /fixboot
```

If `/fixboot` gives “Access Denied”, continue anyway — it’s normal on UEFI systems.

<br>

## Step 5 — Check and Repair System Files

Still in Command Prompt:

<br>

### Check disk for errors

```cmd
chkdsk C: /f /r
```

<br>

### Repair system files

```cmd
sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
```

<br>

### Repair component store (DISM)

```cmd
dism /image:C:\ /cleanup-image /restorehealth
```

<br>

These commands fix:

- Corrupted Windows files  
- Damaged system components  
- Incomplete updates  
- File system errors  

<br>

## Step 6 — Use System Restore (If Enabled)

1. Go to **Troubleshoot**  
2. Select **Advanced options**  
3. Click **System Restore**

Choose a restore point from before the issue occurred.

This does **not** delete personal files.

<br>

## Step 7 — Use System Image Recovery (If Available)

If you previously created a system image:

1. Go to **Troubleshoot**  
2. Select **Advanced options**  
3. Click **System Image Recovery**

This restores Windows exactly as it was when the image was created.

<br>

## Bonus Information

### Accessing Safe Mode from USB Boot
From WinRE:

1. Go to **Troubleshoot**  
2. **Advanced options**  
3. **Startup Settings**  
4. Click **Restart**  
5. Press <kbd>4</kbd> or <kbd>F4</kbd> for Safe Mode

<br>

### Reset Windows Without Losing Files
From WinRE:

**Troubleshoot → Reset this PC → Keep my files**

<br>

This reinstalls Windows but keeps:

- Documents  
- Pictures  
- Desktop files  
- User data  

<br>

### Reset Windows Completely
**Troubleshoot → Reset this PC → Remove everything**

This wipes the system and reinstalls Windows.

<br>

## Compatibility Notes

### Works on:
- Windows 10  
- Windows 11  
- UEFI and Legacy BIOS systems  
- GPT and MBR disks  

### Does NOT work if:
- The USB key is corrupted  
- BIOS/UEFI boot order is locked  
- Secure Boot blocks the USB  
- The disk is physically damaged  

<br>

## Troubleshooting

### USB key does not appear in boot menu
- Try another USB port  
- Disable **Secure Boot** in BIOS  
- Enable **Legacy USB Support**  
- Recreate the USB using Media Creation Tool  

<br>

### Startup Repair loops endlessly
Use manual boot repair commands (Step 4).

<br>

### “Windows cannot find a system image”
Ensure the image is on:
```
D:\WindowsImageBackup
```

<br>

### “Access Denied” on `bootrec /fixboot`
Normal on UEFI systems — continue with other commands.

<br>

## FAQ

### Does this delete my files?
No — unless you choose **Reset → Remove everything**.

### Can I repair Windows without reinstalling?
Yes — Startup Repair, SFC, DISM, and bootrec can fix most issues.

### Do I need a product key?
No — Windows activates automatically after repair.

### Can I use any USB key?
Yes, as long as it is 8GB or larger.

<br>

## Security Notes

- Only repair systems you own or are authorized to maintain  
- Never disable Secure Boot unless necessary  
- Always verify USB media from trusted sources  
- Avoid downloading Windows ISOs from third‑party sites  

<br>

## Final Notes

This guide provides a complete workflow for repairing Windows when it cannot boot.  
Using a bootable USB key and the Windows Recovery Environment, you can fix most startup issues without reinstalling the operating system.
