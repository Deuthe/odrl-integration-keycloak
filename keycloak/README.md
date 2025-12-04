# Keycloak Configuration Documentation

## Realm: ODRL-demo

This document describes the Keycloak configuration used in the ODRL integration project.

## Test User Configuration

### User: testuser
- **Username:** `testuser`
- **Password:** `test`
- **Enabled:** Yes
- **Assigned Roles:**
  - `role-ICT` (provides `role: ICT` claim in JWT)
  - `gemeente-Eindhoven` (provides `gemeente: Eindhoven` claim in JWT)
  - `default-roles-odrl-demo` (default Keycloak role)

## Client Configuration

### Client: odrl-app
- **Client ID:** `odrl-app`
- **Client Secret:** `Mhj3bFw2HaWr8STaAwscMPnlk1Z9DktN`
- **Access Type:** Confidential
- **Direct Access Grants Enabled:** Yes
- **Service Accounts Enabled:** No
- **Standard Flow Enabled:** No
- **Implicit Flow Enabled:** No

### Protocol Mappers

#### 1. role-hardcoded-claim
- **Name:** role-hardcoded-claim
- **Protocol:** openid-connect
- **Protocol Mapper:** Hardcoded claim
- **Claim Name:** role
- **Claim Value:** ICT
- **Token Claim Inclusion:** ID token, access token

#### 2. gemeente-hardcoded-claim
- **Name:** gemeente-hardcoded-claim
- **Protocol:** openid-connect
- **Protocol Mapper:** Hardcoded claim
- **Claim Name:** gemeente
- **Claim Value:** Eindhoven
- **Token Claim Inclusion:** ID token, access token

## Realm Roles

### Available Roles
- `role-ICT` - ICT Department role
- `role-CIO` - Chief Information Officer role (currently unused)
- `gemeente-Eindhoven` - Municipality: Eindhoven
- `gemeente-Amsterdam` - Municipality: Amsterdam (currently unused)
- `default-roles-odrl-demo` - Default realm role
- `offline_access` - Standard Keycloak role
- `uma_authorization` - Standard Keycloak role

## JWT Token Structure

When a user authenticates with the `odrl-app` client, the resulting JWT contains:

```json
{
  "exp": 1234567890,
  "iat": 1234567590,
  "jti": "unique-token-id",
  "iss": "http://localhost:8081/realms/ODRL-demo",
  "aud": "odrl-app",
  "sub": "user-id",
  "typ": "Bearer",
  "azp": "odrl-app",
  "session_state": "session-id",
  "acr": "1",
  "role": "ICT",
  "gemeente": "Eindhoven",
  "scope": "email profile",
  "sid": "session-id",
  "email_verified": false,
  "preferred_username": "testuser"
}
```

## Token Acquisition

### Resource Owner Password Credentials Flow

```bash
curl -X POST "http://localhost:8081/realms/ODRL-demo/protocol/openid-connect/token" \
  -d "client_id=odrl-app" \
  -d "grant_type=password" \
  -d "username=testuser" \
  -d "password=test" \
  -d "client_secret=Mhj3bFw2HaWr8STaAwscMPnlk1Z9DktN"
```

### Response Format

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "not-before-policy": 0,
  "session_state": "session-id",
  "scope": "email profile"
}
```

## ODRL Policy Integration

The JWT claims are designed to work with the ODRL policy in `policies/eindhoven-ict.json`:

```json
{
  "constraint": [
    { "leftOperand": "role", "operator": "eq", "rightOperand": "ICT" },
    { "leftOperand": "gemeente", "operator": "eq", "rightOperand": "Eindhoven" }
  ]
}
```

## Security Notes

1. **Hardcoded Claims:** The current setup uses hardcoded claim mappers for testing purposes. In production, these should be replaced with role-based mappers.
2. **Password Flow:** The Resource Owner Password Credentials flow is used for simplicity. In production, consider using Authorization Code Flow with PKCE.
3. **Client Secret:** The client secret should be stored securely in production environments.
4. **HTTPS:** Always use HTTPS in production to protect token transmission.

## Import Instructions

To recreate this realm in a new Keycloak instance:

1. Navigate to Keycloak Admin Console
2. Select "Add realm"
3. Choose "Import realm"
4. Upload the `ODRL-demo-realm-export.json` file
5. Manually create the test user with the credentials specified above
6. Configure the protocol mappers as documented above

Note: The export doesn't include user credentials for security reasons, so the test user must be created manually after import.