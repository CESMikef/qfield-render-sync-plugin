# Debug Notes - QField Render Sync Plugin

## Current Issues

1. **Token dialog works** ✅
2. **Sync dialog fails to load** ❌ - "Error loading sync dialog"

## Root Cause Analysis

Based on QField documentation and error patterns:

### Issue 1: Dialog Parent Context
- QML Popups need proper parent context
- Must be attached to `iface.mainWindow().contentItem`

### Issue 2: Module Loading
- JavaScript modules in QML are namespaced
- Cannot use `initialize()` pattern
- Must pass modules as parameters

### Issue 3: Missing Error Handling
- No try/catch blocks
- No validation of module loading
- No user-friendly error messages

## Fix Strategy

1. Add comprehensive error logging at every step
2. Validate all prerequisites before loading dialog
3. Add try/catch blocks around critical operations
4. Provide clear user feedback
5. Test each component individually

## Testing Checklist

- [ ] Plugin loads without errors
- [ ] Token dialog appears and works
- [ ] Config loads from API
- [ ] Sync button appears in toolbar
- [ ] Sync dialog opens (no error)
- [ ] Layer selection works
- [ ] Pending photos detected
- [ ] Connection test works
- [ ] Photo upload works
- [ ] Database update works
- [ ] Local layer update works

## Error Messages to Add

1. "Failed to load sync dialog - check QField logs"
2. "No photos found with local paths"
3. "WebDAV upload failed: [reason]"
4. "API update failed: [reason]"
5. "Layer update failed: [reason]"
