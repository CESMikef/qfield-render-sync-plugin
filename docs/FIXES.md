# JavaScript Import Fixes

## Issue

The initial implementation used `.import` statements in JavaScript files, which is QML-specific syntax and causes errors in pure JavaScript files.

```javascript
// ❌ INCORRECT - This doesn't work in JavaScript files
.import "utils.js" as Utils
```

## Solution

JavaScript files in QML projects should be pure JavaScript (ES5) without QML-specific syntax. The imports are handled by the QML files that use them.

### Changes Made

#### 1. Removed `.import` statements from JavaScript files

**Files affected:**
- `js/api_client.js`
- `js/webdav_client.js`
- `js/sync_engine.js`

**Before:**
```javascript
.import "utils.js" as Utils

function someFunction() {
    Utils.log('INFO', 'message');
}
```

**After:**
```javascript
// Pure JavaScript - no imports needed

function someFunction() {
    console.log('[Module] message');
}
```

#### 2. Moved utility functions into modules that need them

Since we can't import between JavaScript files, we duplicated essential utility functions in each module:

**api_client.js:**
- Added `parseErrorMessage()` function

**webdav_client.js:**
- Added `createBasicAuth()` function
- Added `parseErrorMessage()` function
- Added `getFileExtension()` function
- Added `sanitizeFilename()` function
- Added `generatePhotoFilename()` function

**sync_engine.js:**
- Added `isLocalPath()` function
- Added `validateUrl()` function
- Added `validateConfiguration()` function

#### 3. Replaced Utils.* calls with direct function calls

**Before:**
```javascript
Utils.log('INFO', 'message');
Utils.isLocalPath(path);
Utils.validateUrl(url);
```

**After:**
```javascript
console.log('[Module] message');
isLocalPath(path);
validateUrl(url);
```

#### 4. Updated QML imports

**main.qml and SyncDialog.qml:**
```qml
import "../js/utils.js" as Utils
import "../js/webdav_client.js" as WebDAV
import "../js/api_client.js" as API
import "../js/sync_engine.js" as SyncEngine
```

This allows QML to access all functions from each module.

## How QML JavaScript Imports Work

### Correct Pattern

```qml
// In QML file
import "js/mymodule.js" as MyModule

Item {
    function doSomething() {
        // Call functions from the module
        MyModule.someFunction()
    }
}
```

```javascript
// In js/mymodule.js - Pure JavaScript
function someFunction() {
    console.log('Hello from module');
}

function anotherFunction() {
    // Can call other functions in same file
    someFunction();
}
```

### Key Points

1. **JavaScript files are pure JavaScript** - No QML syntax
2. **QML files do the importing** - Using `import` statement
3. **All functions in JS file are accessible** - Via the imported namespace
4. **Functions can call each other** - Within the same file
5. **Cannot import JS from JS** - Only QML can import JS

## Testing

After these fixes, all JavaScript files should:
- ✅ Have no syntax errors
- ✅ Be valid ES5 JavaScript
- ✅ Work when imported by QML
- ✅ Have no `.import` statements

## File Status

| File | Status | Notes |
|------|--------|-------|
| `js/utils.js` | ✅ Fixed | Pure JavaScript, no imports |
| `js/api_client.js` | ✅ Fixed | Added helper functions |
| `js/webdav_client.js` | ✅ Fixed | Added helper functions |
| `js/sync_engine.js` | ✅ Fixed | Added helper functions |
| `main.qml` | ✅ Fixed | Imports all JS modules |
| `components/SyncDialog.qml` | ✅ Fixed | Imports all JS modules |

## Verification

To verify the fixes work:

1. **Check for syntax errors** in IDE
2. **Load plugin in QField** - Should load without errors
3. **Test functionality** - All features should work
4. **Check console logs** - Should see `[Module]` prefixed messages

---

**Last Updated:** 2025-10-06  
**Fix Version:** 1.0.1
