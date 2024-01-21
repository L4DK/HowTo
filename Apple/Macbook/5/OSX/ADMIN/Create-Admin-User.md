How to Create a User account with admin Permissions in Mac OS X

PRE-CHECK/FIXING:
1. Restart your MacBook in a single-user mode: Press and hold ⌘ + S during boot until you see the terminal.
2. Check the filesystem integrity with this command: /sbin/fsck -fy (it’s not necessary, but do it anyway)
3. Mount the root filesystem to get the access full access to the system/disk with this command: /sbin/mount -wu /
4. Fix the permissions with this command: /bin/chmod 1775 /
5 Commit the changes to the filesystem with this command: /bin/sync

Delete AppleSetupDone and Create a New Administrative Account
(forces the “Welcome to Mac OS X” setup assistant to run again, thus allowing you to create a new administrative account.
You can then log in to that new administrative account and reset your original account password,
or copy your old files over if that’s what you’d rather do.)

WORKAROUND THAT ENABLES YOU TO CREATE A LOCAL SYSADMIN USER:
6. Type this command: rm /var/db/.AppleSetupDone
7. type: reboot
8. DONE
