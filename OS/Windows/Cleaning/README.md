# 🧠 **High‑Level Overview**

The script is a **2025‑grade Windows cleanup framework**.  
It is modular, safe, profile‑based, and fully interactive.

<br>

It performs:

- Scanning of temporary/cache folders  
- Age‑based and size‑based filtering  
- Dry‑run preview  
- Deletion queue review  
- Secure deletion with confirmation code  
- Reporting  
- Plugin‑based extension  
- Settings menu  
- Logging

<br>

Everything is wrapped in a modern, colored menu UI.

<br>

# 🧩 **SECTION‑BY‑SECTION EXPLANATION**

Below is a breakdown of what each part of the script does.

<br>

# 1. **Initialization & Global State**

### **Test-IsAdmin**

Checks if the script is running with Administrator privileges.  
Many cleanup paths require admin rights.

<br>

### **Global:FFS_State**

A global object storing:

- Profile (Safe/Standard/Aggressive)  
- Age filter  
- Size filter  
- Targets (folders to scan)  
- Scan results  
- Deletion queue  
- Confirmation code  
- Log file path  
- Loaded plugins  

This acts like a **central memory** for the entire tool.

<br>

### **Write-FFSLog**

Writes messages to:

- Console (with colors)
- Log file

Used everywhere for traceability.

<br>

# 2. **Core Configuration & Profiles**

### **Get-FFSBaseTargets**

Defines the default cleanup folders.

Profiles change how aggressive the cleanup is:

- **Safe** → minimal, harmless  
- **Standard** → includes logs  
- **Aggressive** → includes more caches  

Each target is a structured object:

```
Name
Path
Recursive
```

<br>

### **Import-FFSPlugins**

Loads `.ps1` files from a `plugins/` folder.  
Plugins can add more cleanup targets.

<br>

### **Initialize-FFSTargets**

Builds the final list of folders to scan:

- Base targets  
- Plugin targets  

<br>

# 3. **Utility Functions**

### **New-FFSConfirmationCode**

Generates a random 16‑character code.  
Used to prevent accidental deletion.

<br>

### **Convert-FFSSize**

Converts bytes → KB/MB/GB for readability.

<br>

### **Test-FFSAgeEligible**

Checks if a file is older than X days.

<br>

### **Test-FFSSizeEligible**

Checks if a file is smaller than the max size limit.

These filters prevent deleting:

- Fresh files  
- Large files  
- Recently modified files  

<br>

# 4. **Scanning & Dry‑Run**

### **Invoke-FFSScan**

This is the heart of the dry‑run.

It:

1. Iterates through all targets  
2. Recursively scans files  
3. Applies age filter  
4. Applies size filter  
5. Builds a list of candidate files  
6. Shows progress bar  
7. Stores results in global state  
8. Generates a summary  

<br>

### **Show-FFSScanSummary**
Displays:

- Total files  
- Total size  
- Profile  
- Filters  
- Timestamp  

<br>

# 5. **Deletion Queue**

### **Initialize-FFSDeletionQueue**

Copies scan results into a deletion queue.

This allows:

- Reviewing  
- Filtering  
- Editing  

<br>

### **Show-FFSDeletionQueue**

Shows:

- Number of files  
- Total size  
- First 25 files  

This prevents blind deletion.

<br>

# 6. **Deletion Execution**

### **Invoke-FFSDeletion**

Performs the actual deletion.

Steps:

1. Shows total files + size  
2. Generates confirmation code  
3. User must type the code  
4. Deletes files one by one  
5. Logs success/failure  
6. Shows progress bar  

This is the **safety‑critical** part.

<br>

# 7. **Report Generation**

### **New-FFSReport**

Creates a text report containing:

- Summary  
- Top 50 largest files  
- Paths  
- Sizes  
- Timestamps  

Stored in `%TEMP%`.

Useful for:

- Auditing  
- Troubleshooting  
- Documentation  

<br>

# 8. **Settings Menu**

### **Show-FFSSettings**
Allows the user to change:

- Profile  
- Age filter  
- Size filter  
- Reinitialize targets  

This makes the tool flexible and customizable.

<br>

# 9. **Main Menu System**

### **Show-FFSHeader**
Draws the ASCII UI header.

<br>

### **Start-FFSMenu**
The main loop:

- Scan  
- Show summary  
- Build deletion queue  
- Review queue  
- Execute deletion  
- Generate report  
- Settings  
- Exit  

This is the user’s primary interface.

<br>

# 10. **Script Entry Point**

### **Start-FFSMenu**
Runs the tool.

<br>

# 🏁 **In Short**

Here’s the entire flow simplified:

1. Load settings
2. Load plugins
3. Build target list
4. Show menu:

User chooses:
  - Scan
  - Review
  - Delete
  - Report
  - Settings

5. All actions logged
6. Deletion requires confirmation code
