# QField Render Sync Plugin - Logging Guide

## Overview

The QField Render Sync Plugin includes a comprehensive logging system to help you debug issues when using QField Desktop. All logs are written to both the console and tagged with `[FILE_LOG]` for easy filtering.

## How Logging Works

The plugin uses a custom logger module (`logger.js`) that:
- Writes detailed logs with timestamps
- Includes log levels (INFO, WARN, ERROR, DEBUG)
- Captures function entry/exit points
- Logs HTTP requests and responses
- Tracks sync progress

## Capturing Logs in QField Desktop

### Method 1: Console Output Redirection (Recommended)

When running QField Desktop from the command line, you can redirect console output to a file:

#### Windows (PowerShell):
```powershell
# Navigate to QField installation directory
cd "C:\Program Files\QField"

# Run QField and capture logs
.\qfield.exe 2>&1 | Tee-Object -FilePath "C:\Users\YourName\qfield_debug.log"
```

#### Windows (Command Prompt):
```cmd
cd "C:\Program Files\QField"
qfield.exe > C:\Users\YourName\qfield_debug.log 2>&1
```

#### Linux:
```bash
qfield 2>&1 | tee ~/qfield_debug.log
```

#### macOS:
```bash
/Applications/QField.app/Contents/MacOS/QField 2>&1 | tee ~/qfield_debug.log
```

### Method 2: Filter Console Output

All file logs are tagged with `[FILE_LOG]` prefix. You can filter them:

#### Windows (PowerShell):
```powershell
.\qfield.exe 2>&1 | Select-String -Pattern "\[FILE_LOG\]" | Out-File -FilePath "C:\Users\YourName\qfield_filtered.log"
```

#### Linux/macOS:
```bash
qfield 2>&1 | grep "\[FILE_LOG\]" > ~/qfield_filtered.log
```

### Method 3: Use QField Desktop's Built-in Logging

QField Desktop may have built-in logging capabilities. Check:
- **Settings → Advanced → Enable Debug Logging**
- Log files are typically stored in:
  - Windows: `C:\Users\YourName\AppData\Local\QField\logs\`
  - Linux: `~/.local/share/QField/logs/`
  - macOS: `~/Library/Application Support/QField/logs/`

## Log File Location

By default, the plugin attempts to write logs to:
```
Documents/qfield_render_sync_debug.log
```

You can customize this by setting a QGIS project variable:
- Variable name: `render_log_file`
- Value: Full path to your desired log file (e.g., `C:/Users/YourName/my_debug.log`)

## Log Levels

The logger uses four log levels:

### INFO
General information about plugin operations:
```
[2025-10-09T14:19:28.123Z] [INFO ] Plugin version: 2.8.0
[2025-10-09T14:19:28.456Z] [INFO ] Configuration loaded successfully
```

### WARN
Warnings that don't prevent operation but may indicate issues:
```
[2025-10-09T14:19:30.789Z] [WARN ] HTTP 404 ← https://api.example.com/photos
```

### ERROR
Errors that prevent operations from completing:
```
[2025-10-09T14:19:35.012Z] [ERROR] Upload failed for feature ABC123
  Data: {
    "message": "Network timeout",
    "stack": "..."
  }
```

### DEBUG
Detailed debugging information:
```
[2025-10-09T14:19:28.345Z] [DEBUG] → ENTER: syncPhoto
[2025-10-09T14:19:28.678Z] [DEBUG] HTTP POST → https://api.example.com/upload
```

## Reading Log Files

### Log Entry Format

Each log entry follows this format:
```
[TIMESTAMP] [LEVEL] MESSAGE
  Data: { ... optional JSON data ... }
```

Example:
```
[2025-10-09T14:19:28.123Z] [INFO ] Starting sync of 5 photos
[2025-10-09T14:19:28.456Z] [DEBUG] → ENTER: syncPhoto
  Data: {
    "globalId": "ABC123",
    "localPath": "C:/photos/photo1.jpg"
  }
[2025-10-09T14:19:29.789Z] [INFO ] Sync Progress: 1/5 (20%) - Uploading to WebDAV...
[2025-10-09T14:19:32.012Z] [INFO ] Sync Progress: 1/5 (20%) - Updating database...
[2025-10-09T14:19:33.345Z] [DEBUG] ← EXIT: syncPhoto
  Data: {
    "success": true,
    "photoUrl": "https://webdav.example.com/photos/ABC123.jpg"
  }
```

### Filtering Logs

#### By Level:
```powershell
# Windows PowerShell
Get-Content qfield_debug.log | Select-String -Pattern "\[ERROR\]"
Get-Content qfield_debug.log | Select-String -Pattern "\[WARN\]"
```

```bash
# Linux/macOS
grep "\[ERROR\]" qfield_debug.log
grep "\[WARN\]" qfield_debug.log
```

#### By Function:
```powershell
# Windows PowerShell
Get-Content qfield_debug.log | Select-String -Pattern "syncPhoto"
```

```bash
# Linux/macOS
grep "syncPhoto" qfield_debug.log
```

#### By Time Range:
```powershell
# Windows PowerShell - logs from specific hour
Get-Content qfield_debug.log | Select-String -Pattern "2025-10-09T14:"
```

```bash
# Linux/macOS
grep "2025-10-09T14:" qfield_debug.log
```

## Common Debugging Scenarios

### 1. Plugin Not Loading

Look for initialization logs:
```
grep "Plugin loading" qfield_debug.log
grep "Plugin loaded" qfield_debug.log
```

Common issues:
- Missing dependencies
- QML syntax errors
- Permission issues

### 2. Token/Configuration Issues

Filter for configuration-related logs:
```
grep -i "token\|config" qfield_debug.log
```

Look for:
- `[ERROR] Invalid token`
- `[WARN] Configuration incomplete`
- `[INFO] Configuration loaded successfully`

### 3. Photo Upload Failures

Filter for upload-related logs:
```
grep -i "upload\|webdav" qfield_debug.log
```

Common issues:
- Network connectivity
- WebDAV authentication
- File permissions
- File size limits

### 4. Database Update Failures

Filter for API-related logs:
```
grep -i "api\|database" qfield_debug.log
```

Look for:
- HTTP status codes (404, 401, 500, etc.)
- Network timeouts
- Invalid global IDs

### 5. Layer Detection Issues

Filter for layer-related logs:
```
grep -i "layer\|vector" qfield_debug.log
```

Look for:
- `[INFO] Found X vector layers`
- `[ERROR] No layer selected`
- `[WARN] Layer missing photo field`

## Advanced Debugging

### Enable Verbose Logging

The logger automatically captures:
- All function entries and exits (DEBUG level)
- HTTP request/response details
- Sync progress updates
- Error stack traces

### Analyze Sync Performance

Look for timing patterns:
```bash
# Extract timestamps for a specific photo sync
grep "ABC123" qfield_debug.log | grep -E "\[INFO \]|\[DEBUG\]"
```

Calculate time between operations to identify bottlenecks.

### Export Logs for Support

When reporting issues, include:

1. **Full log file** (if small) or **filtered logs** (if large)
2. **Plugin version** (found in first few lines)
3. **Timestamp range** of the issue
4. **Specific error messages**

Example export command:
```bash
# Export last 500 lines with errors and warnings
tail -n 500 qfield_debug.log | grep -E "\[ERROR\]|\[WARN\]" > issue_report.log
```

## Troubleshooting the Logger

### Logger Not Initializing

If you don't see log entries:

1. **Check console output** - Logs always go to console
2. **Verify QField Desktop** - File logging works best in QField Desktop
3. **Check permissions** - Ensure write access to log directory
4. **Look for initialization errors**:
   ```
   grep "Logger" qfield_debug.log
   grep "File logging" qfield_debug.log
   ```

### Log File Not Created

The logger uses console output with `[FILE_LOG]` tags. To create an actual file:
- Use console redirection (see Method 1 above)
- Or filter console output to a file (see Method 2 above)

### Too Many Logs

To reduce log volume:

1. **Filter by level** - Only capture WARN and ERROR:
   ```bash
   qfield 2>&1 | grep -E "\[WARN \]|\[ERROR\]" > qfield_errors.log
   ```

2. **Filter by component**:
   ```bash
   qfield 2>&1 | grep "Render Sync" > qfield_plugin.log
   ```

## Log Rotation

For long-running sessions, consider log rotation:

### Windows (PowerShell):
```powershell
# Rotate log if it exceeds 10MB
$logFile = "C:\Users\YourName\qfield_debug.log"
if ((Get-Item $logFile).Length -gt 10MB) {
    Move-Item $logFile "$logFile.old"
}
```

### Linux/macOS:
```bash
# Rotate log if it exceeds 10MB
LOG_FILE=~/qfield_debug.log
if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE") -gt 10485760 ]; then
    mv "$LOG_FILE" "$LOG_FILE.old"
fi
```

## Best Practices

1. **Start fresh** - Clear old logs before debugging a new issue
2. **Capture everything** - Use full console redirection during debugging
3. **Filter later** - It's easier to filter a complete log than to miss important details
4. **Include timestamps** - Always include timestamp context when reporting issues
5. **Share logs securely** - Logs may contain tokens or sensitive data - review before sharing

## Example Debugging Session

```bash
# 1. Clear old logs
rm ~/qfield_debug.log

# 2. Start QField with logging
qfield 2>&1 | tee ~/qfield_debug.log

# 3. Reproduce the issue in QField

# 4. Stop QField (Ctrl+C in terminal)

# 5. Analyze logs
grep "\[ERROR\]" ~/qfield_debug.log
grep "\[WARN\]" ~/qfield_debug.log

# 6. Extract relevant section
grep -A 10 -B 5 "specific error message" ~/qfield_debug.log > issue_report.log

# 7. Share issue_report.log with support
```

## Getting Help

If you're still experiencing issues after reviewing logs:

1. **Collect logs** using the methods above
2. **Identify the error** - Find ERROR or WARN messages
3. **Note the context** - Include surrounding log entries
4. **Report the issue** with:
   - Plugin version
   - QField version
   - Operating system
   - Steps to reproduce
   - Relevant log excerpts

## Additional Resources

- [Testing Guide](TESTING.md) - Comprehensive testing procedures
- [Deployment Guide](DEPLOYMENT.md) - Installation and setup
- [Workflow Guide](WORKFLOW_GUIDE.md) - Field usage instructions
