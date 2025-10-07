# QField Render Sync - Testing Guide

## Overview

Comprehensive testing guide for the QField Render Sync plugin. This document covers unit testing, integration testing, and field testing procedures.

## Test Environment Setup

### Prerequisites

1. **Development Environment**
   - QGIS Desktop 3.x
   - QField 3.0+ on mobile device or emulator
   - Access to test database
   - Access to test WebDAV server

2. **Test Data**
   - Test QGIS project with sample features
   - Sample photos (various sizes: 1MB, 5MB, 10MB)
   - Test layer with global_id and photo fields

3. **Test Credentials**
   - WebDAV: `qfield` / `qfield123`
   - API Token: `qwrfzf23t2345t23fef23123r`
   - Database: Test schema/table

---

## Unit Tests

### JavaScript Module Tests

#### Test utils.js

```javascript
// Test 1: URL Validation
console.assert(validateUrl("https://example.com") === true, "Valid HTTPS URL")
console.assert(validateUrl("http://example.com") === true, "Valid HTTP URL")
console.assert(validateUrl("ftp://example.com") === false, "Invalid protocol")
console.assert(validateUrl("") === false, "Empty string")
console.assert(validateUrl(null) === false, "Null value")

// Test 2: Local Path Detection
console.assert(isLocalPath("/path/to/file.jpg") === true, "Unix path")
console.assert(isLocalPath("C:\\path\\to\\file.jpg") === true, "Windows path")
console.assert(isLocalPath("https://example.com/file.jpg") === false, "URL not local")
console.assert(isLocalPath("") === false, "Empty string")

// Test 3: Filename Sanitization
console.assert(sanitizeFilename("test file.jpg") === "test_file.jpg", "Spaces replaced")
console.assert(sanitizeFilename("test/file.jpg") === "test_file.jpg", "Slashes replaced")
console.assert(sanitizeFilename("test\\file.jpg") === "test_file.jpg", "Backslashes replaced")

// Test 4: File Extension Extraction
console.assert(getFileExtension("photo.jpg") === "jpg", "JPG extension")
console.assert(getFileExtension("photo.PNG") === "png", "PNG lowercase")
console.assert(getFileExtension("photo") === "jpg", "No extension defaults to jpg")

// Test 5: Configuration Validation
var validConfig = {
    webdavUrl: "https://example.com",
    webdavUsername: "user",
    webdavPassword: "pass",
    apiUrl: "https://api.example.com",
    apiToken: "token123"
}
var validation = validateConfiguration(validConfig)
console.assert(validation.valid === true, "Valid configuration")
console.assert(validation.missing.length === 0, "No missing fields")

var invalidConfig = {
    webdavUrl: "",
    webdavUsername: "user",
    webdavPassword: "",
    apiUrl: "https://api.example.com",
    apiToken: ""
}
validation = validateConfiguration(invalidConfig)
console.assert(validation.valid === false, "Invalid configuration")
console.assert(validation.missing.length === 3, "Three missing fields")
```

#### Test webdav_client.js

```javascript
// Test 1: File Existence Check
checkFileExists(
    "https://qfield-photo-storage-v3.onrender.com/test.jpg",
    "qfield",
    "qfield123",
    function(exists, error) {
        console.log("File exists test:", exists ? "EXISTS" : "NOT FOUND", error || "")
    }
)

// Test 2: Connection Test
testConnection(
    "https://qfield-photo-storage-v3.onrender.com",
    "qfield",
    "qfield123",
    function(success, error) {
        console.assert(success === true, "WebDAV connection successful")
        console.log("WebDAV connection:", success ? "✓" : "✗", error || "")
    }
)

// Test 3: Invalid Credentials
testConnection(
    "https://qfield-photo-storage-v3.onrender.com",
    "wrong",
    "wrong",
    function(success, error) {
        console.assert(success === false, "Invalid credentials should fail")
        console.assert(error.includes("Authentication"), "Error mentions authentication")
    }
)
```

#### Test api_client.js

```javascript
// Test 1: Health Check
testConnection(
    "https://ces-qgis-qfield-v1.onrender.com",
    "qwrfzf23t2345t23fef23123r",
    function(success, error) {
        console.assert(success === true, "API connection successful")
        console.log("API connection:", success ? "✓" : "✗", error || "")
    }
)

// Test 2: Get Photo Status
getPhotoStatus(
    "https://ces-qgis-qfield-v1.onrender.com",
    "qwrfzf23t2345t23fef23123r",
    "test-global-id",
    "design.verify_poles",
    function(success, data, error) {
        console.log("Photo status:", success ? "✓" : "✗", error || "")
        if (success) {
            console.log("Photo URL:", data.photo_url)
            console.log("Has photo:", data.has_photo)
        }
    }
)

// Test 3: Invalid Token
testConnection(
    "https://ces-qgis-qfield-v1.onrender.com",
    "invalid-token",
    function(success, error) {
        console.assert(success === false, "Invalid token should fail")
    }
)
```

---

## Integration Tests

### Test 1: Complete Sync Workflow

**Objective:** Verify end-to-end photo sync process

**Steps:**
1. Create test feature with local photo
2. Run sync process
3. Verify photo uploaded to WebDAV
4. Verify database updated
5. Verify local layer updated

**Expected Results:**
- Photo uploaded successfully
- Database contains photo URL
- Local feature shows URL instead of path
- No errors reported

**Test Script:**
```javascript
// Setup
var testFeature = {
    globalId: "test-" + Date.now(),
    localPath: "/path/to/test/photo.jpg"
}

// Execute sync
syncPhoto(
    { feature: testFeature, globalId: testFeature.globalId, localPath: testFeature.localPath },
    config,
    layer,
    function(percent, status) {
        console.log("Progress:", percent + "%", status)
    },
    function(success, photoUrl, error) {
        console.assert(success === true, "Sync should succeed")
        console.assert(photoUrl !== null, "Photo URL should be returned")
        console.assert(error === null, "No error should occur")
        console.log("Sync result:", success ? "✓" : "✗", photoUrl, error || "")
    }
)
```

### Test 2: Duplicate Prevention

**Objective:** Verify duplicate photos are not re-uploaded

**Steps:**
1. Upload photo once
2. Attempt to upload same photo again
3. Verify second upload is skipped

**Expected Results:**
- First upload succeeds
- Second upload skips (already exists)
- Both complete successfully
- Only one file on WebDAV

### Test 3: Batch Sync

**Objective:** Verify multiple photos sync correctly

**Steps:**
1. Create 10 test features with photos
2. Run batch sync
3. Verify all photos uploaded
4. Verify all database records updated

**Expected Results:**
- All 10 photos uploaded
- All 10 database records updated
- Progress tracking accurate
- No errors

### Test 4: Error Handling

**Objective:** Verify graceful error handling

**Test Cases:**

**4a. Network Failure**
- Disable internet
- Attempt sync
- Verify error message displayed
- Verify no partial updates

**4b. Invalid Credentials**
- Use wrong WebDAV password
- Attempt sync
- Verify authentication error shown
- Verify sync stops gracefully

**4c. Missing Feature**
- Use non-existent global_id
- Attempt sync
- Verify "Feature not found" error
- Verify photo still uploaded (if applicable)

**4d. Large File Timeout**
- Upload very large file (50MB+)
- Verify timeout handling
- Verify retry mechanism

---

## UI Tests

### Test 1: Plugin Loading

**Steps:**
1. Open QField with configured project
2. Verify plugin loads
3. Check toolbar button appears
4. Verify button is enabled

**Expected Results:**
- Plugin loads without errors
- Toolbar button visible
- Button enabled (if config valid)
- Toast notification shown

### Test 2: Sync Dialog

**Steps:**
1. Click "Sync Photos" button
2. Verify dialog opens
3. Check layer dropdown populated
4. Verify pending count shown

**Expected Results:**
- Dialog opens smoothly
- Layers listed correctly
- Pending count accurate
- All UI elements visible

### Test 3: Connection Test

**Steps:**
1. Open sync dialog
2. Click "Test Connections"
3. Wait for results

**Expected Results:**
- WebDAV: ✓ Connected
- API: ✓ Connected
- Results shown within 10 seconds

### Test 4: Progress Tracking

**Steps:**
1. Start sync with multiple photos
2. Observe progress bar
3. Check status messages

**Expected Results:**
- Progress bar updates smoothly
- Status messages accurate
- Current photo count shown
- Success/failure count updates

---

## Field Tests

### Test 1: Real Device Testing

**Environment:** Actual mobile device (Android/iOS)

**Steps:**
1. Install plugin on device
2. Download project from QFieldCloud
3. Navigate to field location
4. Capture real photo
5. Sync photo
6. Verify upload

**Expected Results:**
- Plugin works on real device
- Photo captures correctly
- Sync completes successfully
- Photo viewable in database

### Test 2: Offline/Online Transition

**Steps:**
1. Capture photos while offline
2. Attempt sync (should fail gracefully)
3. Go online
4. Retry sync
5. Verify success

**Expected Results:**
- Offline sync shows clear error
- No crashes or data loss
- Online sync succeeds
- All photos uploaded

### Test 3: Various Photo Sizes

**Test Cases:**
- Small photo (< 1MB)
- Medium photo (1-5MB)
- Large photo (5-10MB)
- Very large photo (> 10MB)

**Expected Results:**
- All sizes upload successfully
- Progress tracking accurate
- No timeouts (or handled gracefully)

### Test 4: Network Conditions

**Test Cases:**
- WiFi (fast)
- 4G/LTE (medium)
- 3G (slow)
- Intermittent connection

**Expected Results:**
- Adapts to network speed
- Timeouts handled appropriately
- Retry logic works
- User informed of issues

---

## Performance Tests

### Test 1: Upload Speed

**Objective:** Measure upload performance

**Method:**
- Upload 10 photos (5MB each)
- Measure total time
- Calculate average time per photo

**Acceptance Criteria:**
- < 30 seconds per photo on WiFi
- < 60 seconds per photo on 4G
- Progress tracking accurate within 5%

### Test 2: Memory Usage

**Objective:** Verify no memory leaks

**Method:**
- Monitor memory usage
- Sync 50 photos
- Check memory after completion

**Acceptance Criteria:**
- Memory usage stable
- No significant increase after sync
- No crashes

### Test 3: Battery Impact

**Objective:** Measure battery consumption

**Method:**
- Note battery level before sync
- Sync 20 photos
- Note battery level after sync

**Acceptance Criteria:**
- < 5% battery drain for 20 photos
- No excessive CPU usage
- No background drain

---

## Regression Tests

Run after any code changes:

1. **Configuration Loading**
   - [ ] Project variables load correctly
   - [ ] Missing variables detected
   - [ ] Invalid values rejected

2. **Photo Detection**
   - [ ] Local paths identified
   - [ ] URLs ignored
   - [ ] Empty fields handled

3. **Upload Process**
   - [ ] WebDAV upload works
   - [ ] Duplicate check works
   - [ ] Progress tracking accurate

4. **Database Update**
   - [ ] API calls succeed
   - [ ] Retry logic works
   - [ ] Errors handled gracefully

5. **UI Functionality**
   - [ ] Dialog opens/closes
   - [ ] Layer selection works
   - [ ] Progress displays correctly
   - [ ] Results shown accurately

---

## Test Data

### Sample Project Variables

```
render_webdav_url = https://qfield-photo-storage-v3.onrender.com
render_webdav_username = qfield
render_webdav_password = qfield123
render_api_url = https://ces-qgis-qfield-v1.onrender.com
render_api_token = qwrfzf23t2345t23fef23123r
render_db_table = design.verify_poles
render_photo_field = photo
```

### Sample Test Features

```sql
-- Create test feature
INSERT INTO design.verify_poles (global_id, photo, updated_at)
VALUES ('test-feature-001', NULL, NOW());

-- Verify upload
SELECT global_id, photo, updated_at
FROM design.verify_poles
WHERE global_id = 'test-feature-001';
```

---

## Test Reporting

### Test Report Template

```
Test Name: [Test Name]
Date: [Date]
Tester: [Name]
Environment: [Device/OS/QField Version]

Results:
- Total Tests: [N]
- Passed: [N]
- Failed: [N]
- Skipped: [N]

Failed Tests:
1. [Test Name] - [Reason]
2. [Test Name] - [Reason]

Notes:
[Additional observations]

Status: [PASS/FAIL]
```

---

## Automated Testing (Future)

### Unit Test Framework

Consider implementing:
- QML Test framework
- JavaScript unit tests
- Continuous integration

### Integration Test Automation

- Automated API testing
- WebDAV upload verification
- Database validation

---

## Sign-Off Checklist

Before production release:

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] UI tests complete
- [ ] Field tests successful
- [ ] Performance acceptable
- [ ] Error handling verified
- [ ] Documentation reviewed
- [ ] Security audit complete
- [ ] Backup/rollback tested

---

**Last Updated:** 2025-10-06  
**Testing Guide Version:** 1.0.0
