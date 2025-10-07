# API Endpoint for Token-Based Configuration

## Overview

The plugin now uses a token-based authentication system. Users enter their token in QField, and the plugin fetches all configuration from your API.

---

## Required API Endpoint

### **GET /api/config**

**Purpose**: Return client configuration based on token

**Authentication**: Bearer token in header OR token query parameter

**Request**:
```
GET /api/config?token={user_token}
Authorization: Bearer {user_token}
```

**Response** (200 OK):
```json
{
  "webdav_url": "https://qfield-photo-storage-v3.onrender.com",
  "webdav_username": "qfield",
  "webdav_password": "qfield123",
  "db_table": "design.verify_poles",
  "photo_field": "photo",
  "DB_HOST": "https://qfield-photo-storage-v3.onrender.com",
  "DB_USER": "qfield",
  "DB_PASSWORD": "qfield123",
  "ALLOWED_SCHEMA": "design",
  "DB_POOL_SIZE": 10
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing token
- `403 Forbidden`: Token valid but no access
- `404 Not Found`: Token not found in database

---

## Database Query

The endpoint should query your `api.client_config` table:

```sql
SELECT 
    key,
    value,
    token,
    client_integer,
    client_name,
    created_at,
    updated_at
FROM api.client_config
WHERE token = $1
  AND (updated_at IS NULL OR updated_at > NOW() - INTERVAL '90 days');
```

---

## Example FastAPI Implementation

```python
from fastapi import APIRouter, HTTPException, Header, Query
from typing import Optional
import asyncpg

router = APIRouter()

@router.get("/api/config")
async def get_config(
    token: str = Query(..., description="Client token"),
    authorization: Optional[str] = Header(None)
):
    """
    Get client configuration by token.
    Token can be provided via query parameter or Authorization header.
    """
    
    # Extract token from header if provided
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "")
    
    if not token:
        raise HTTPException(status_code=401, detail="Token required")
    
    # Query database
    async with get_db_connection() as conn:
        rows = await conn.fetch(
            """
            SELECT key, value
            FROM api.client_config
            WHERE token = $1
            """,
            token
        )
    
    if not rows:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    # Build configuration object
    config = {}
    for row in rows:
        config[row['key']] = row['value']
    
    # Ensure required fields exist
    required_fields = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'ALLOWED_SCHEMA']
    for field in required_fields:
        if field not in config:
            raise HTTPException(status_code=500, detail=f"Missing configuration: {field}")
    
    # Map to plugin-expected format
    return {
        "webdav_url": config.get('DB_HOST'),
        "webdav_username": config.get('DB_USER'),
        "webdav_password": config.get('DB_PASSWORD'),
        "db_table": f"{config.get('ALLOWED_SCHEMA')}.verify_poles",
        "photo_field": "photo",
        "DB_HOST": config.get('DB_HOST'),
        "DB_USER": config.get('DB_USER'),
        "DB_PASSWORD": config.get('DB_PASSWORD'),
        "ALLOWED_SCHEMA": config.get('ALLOWED_SCHEMA'),
        "DB_POOL_SIZE": int(config.get('DB_POOL_SIZE', 10))
    }
```

---

## Testing the Endpoint

### Using curl:
```bash
curl -X GET "https://ces-qgis-qfield-v1.onrender.com/api/config?token=qwrfzf23t2345t23fef23123r"
```

### Using curl with Bearer token:
```bash
curl -X GET "https://ces-qgis-qfield-v1.onrender.com/api/config" \
  -H "Authorization: Bearer qwrfzf23t2345t23fef23123r"
```

### Expected Response:
```json
{
  "webdav_url": "https://qfield-photo-storage-v3.onrender.com",
  "webdav_username": "qfield",
  "webdav_password": "qfield123",
  "db_table": "design.verify_poles",
  "photo_field": "photo"
}
```

---

## Security Considerations

1. **HTTPS Only**: Endpoint must use HTTPS
2. **Token Validation**: Verify token exists and is active
3. **Rate Limiting**: Implement rate limiting to prevent abuse
4. **Token Expiry**: Consider implementing token expiration
5. **Audit Logging**: Log all configuration requests

---

## Plugin Behavior

1. **First Use**: User clicks "Sync Photos" → Token dialog appears
2. **Enter Token**: User enters token from `api.client_config` table
3. **Fetch Config**: Plugin calls `/api/config?token={token}`
4. **Store Token**: Token saved locally in QField project settings
5. **Auto-Load**: On subsequent launches, token is loaded automatically

---

## Token Management

### Generate New Token:
```sql
INSERT INTO api.client_config (token, key, value, client_name)
VALUES 
  ('qwrfzf23t2345t23fef23123r', 'DB_HOST', 'https://qfield-photo-storage-v3.onrender.com', 'CES'),
  ('qwrfzf23t2345t23fef23123r', 'DB_USER', 'qfield', 'CES'),
  ('qwrfzf23t2345t23fef23123r', 'DB_PASSWORD', 'qfield123', 'CES'),
  ('qwrfzf23t2345t23fef23123r', 'ALLOWED_SCHEMA', 'design', 'CES'),
  ('qwrfzf23t2345t23fef23123r', 'DB_POOL_SIZE', '10', 'CES');
```

### Revoke Token:
```sql
DELETE FROM api.client_config WHERE token = 'qwrfzf23t2345t23fef23123r';
```

---

## Next Steps

1. **Implement the `/api/config` endpoint** in your FastAPI application
2. **Test the endpoint** with curl or Postman
3. **Update v2.0.0 plugin** in QField
4. **Enter token** when prompted
5. **Verify configuration loads** successfully

---

**Last Updated**: 2025-10-07  
**Version**: 2.0.0
