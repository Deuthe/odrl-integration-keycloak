## Recent Changes and Enhancements

This section outlines the significant updates and improvements made to the original PoC project: https://github.com/Deuthe/test-odrl-integration

### Authentication Migration to Keycloak:
*   **Keycloak Integration:** The system now uses Keycloak as the JWT provider instead of Paradym. Keycloak issues RS256-signed JWT tokens with user roles and municipality claims.
*   **Updated Token Validation:** The PAP service now decodes and validates Keycloak-issued JWTs, removing the need for Paradym-specific public key verification.
*   **Realm Configuration:** A working Keycloak realm "ODRL-demo" is pre-configured with test user credentials and role mappings.

### File and Codebase Cleanup:
*   **Paradym Files Removed:** All Paradym-related files including `keys/paradym_wallet_public.pem`, `verify_jwt.py`, and `DockerApi/` directory have been removed.
*   **Duplicate Data Files Removed:** Redundant `airquality_data_kennedylaan.json`, `soundlevel_data_kennedylaan.json`, and `traffic_data_kennedylaan.json` files were removed from the root directory. The canonical versions reside in `mock-data/`.

### Frontend UI/UX Improvements:
*   **Keycloak JWT Integration:** The dashboard now expects a JWT issued by Keycloak. The UI has been updated to allow users to paste their Keycloak-issued JWT directly.
*   **Architecture Diagram Relocation:** The system architecture diagram is no longer displayed on the main dashboard. It now appears dynamically within a popup modal when the "Test Protected Endpoint" button is clicked, providing contextual visualization during the simulation.
*   **Reordered Interaction Steps:** The dashboard's interactive steps have been reordered to better emphasize policy governance:
    1.  **Live Policy Editor:** Define and update ODRL policies.
    2.  **Backend Log:** Monitor real-time interactions with the backend services.
    3.  **Provide Keycloak JWT:** Paste JWT tokens obtained from Keycloak.
    4.  **Test Protected Endpoint:** Simulate access requests to data resources.
    5.  **Final Result:** View the outcome of the access request.
*   **Scrollable Backend Log:** The "Backend Log" area is now scrollable, preventing content overflow and maintaining layout integrity when extensive log data is generated.
*   **Dark Mode Theme:** The entire interactive dashboard features a new dark mode theme for improved visual comfort and modern aesthetics.

---

## Architecture

This environment is composed of several microservices orchestrated by `docker-compose.yml`:

- **APISIX (`:9088`)**: The API Gateway and the single entry point for all traffic. It is responsible for:
  - Serving the frontend dashboard (`/`).
  - Routing requests to backend services with CORS support.
  - Proxying requests to the appropriate backend services (`/pap/*` to the PAP, `/data/*` to the PAP).

- **Keycloak (`:8081`)**: The identity and access management server responsible for:
  - User authentication and authorization.
  - Issuing RS256-signed JWT tokens with user roles and municipality claims.
  - Providing a pre-configured realm "ODRL-demo" with test user credentials.

- **PAP (Policy Administration Point)**: A custom Node.js service responsible for:
  - Decoding and validating Keycloak-issued JWTs.
  - Receiving ODRL policies and translating them into OPA's Rego language (`/policies`).
  - Handling requests for protected data (`/data/*`), where it queries OPA for an authorization decision before proxying to the `mock-data` service.

- **OPA (Open Policy Agent) (`:8181`)**: The policy decision point. It runs as a standalone server and makes authorization decisions based on the Rego policies loaded by the PAP.

- **PostgreSQL**: Database backend for Keycloak, storing user credentials, roles, and realm configuration.

- **etcd**: A key-value store that holds all of APISIX's dynamic configuration (routes, consumers, etc.).

- **Mock Data**: An NGINX server that hosts various static JSON data files (e.g., `airquality_data_kennedylaan.json`, `soundlevel_data_kennedylaan.json`, `traffic_data_kennedylaan.json`), representing protected resources.

- **Frontend**: An NGINX server that hosts the `index.html` dashboard (served via APISIX).

---

## Prerequisites

- Docker
- Docker Compose

---

## Replication on Other Machines

To replicate this environment on other machines:

### 1. Clone the Repository
```sh
git clone <repository-url>
cd test-odrl-integration
```

### 2. Update IP Addresses
Before starting services, update the following files with your machine's IP address:

- **README.md:** Replace `192.168.2.131` with your machine's IP
- **index.html:** Update `APISIX_GATEWAY_HTTP` constant with your IP

### 3. Start Services
```sh
docker compose up -d --build
```

### 4. Initialize Configuration
```sh
./init-apisix.sh
```

### 5. Import Keycloak Realm
The Keycloak realm needs to be manually configured:

1. Navigate to Keycloak Admin Console: http://localhost:8081
2. Login with admin/admin
3. Add realm "ODRL-demo" using `keycloak/ODRL-demo-realm-export.json`
4. Create test user with credentials documented in `keycloak/README.md`

### 6. Access Dashboard
Update the IP in your browser to access: http://your-machine-ip:9088

**Note:** The current configuration uses `192.168.2.131` as the example IP. Replace this with your actual machine IP for proper functionality.

---

## Quick Start

Getting the environment running is a simple two-step process.

### 1. Start the Services

Build and start all the services in the background:

```sh
docker compose up -d --build
```

### 2. Initialize the Configuration

After the services have started, run the initialization script. This will automatically configure APISIX (routes, upstreams) and push the initial policy to OPA.

```sh
./init-apisix.sh
```

Wait for the script to complete. You should see "Initialization complete!" at the end.

### 3. Keycloak Realm Configuration

The system includes a pre-configured Keycloak realm "ODRL-demo" with the following setup:

- **Test User Credentials:**
  - Username: `testuser`
  - Password: `test`
  - Assigned Roles: `role-ICT`, `gemeente-Eindhoven`

- **Client Configuration:**
  - Client ID: `odrl-app`
  - Client Secret: `Mhj3bFw2HaWr8STaAwscMPnlk1Z9DktN`
  - Grant Type: Password (Resource Owner Password Credentials)

The realm configuration is exported in `keycloak/ODRL-demo-realm-export.json` for reference and backup.

---

## Usage and Testing

The entire system can now be tested using the interactive web dashboard. The script automatically configured APISIX to serve the dashboard.

**Access the dashboard here:** [http://192.168.2.131:9088](http://192.168.2.131:9088)
*(Note: Use your VM's IP address if you are not running this on localhost)*

### Understanding the Interactive Dashboard

The dashboard provides a guided workflow to interact with the ODRL authorization system. The steps are designed to emphasize policy governance:

1.  **Step 1: Live Policy Editor**: This section allows you to directly edit the ODRL policy that governs access to resources. Any changes made here can be pushed to the PAP service, which then translates and loads them into OPA.
2.  **Step 2: Backend Log**: Located next to the Policy Editor, this area displays real-time logs from the backend services, providing immediate feedback on policy updates, JWT generation, and access requests. It is now scrollable to accommodate extensive log data.
3.  **Step 3: Provide Keycloak JWT**: This section allows you to paste your RS256-signed JWT token obtained from Keycloak. Click "Use this JWT" to make the token available for testing protected endpoints.
4.  **Step 4: Test Protected Endpoint**: Select a data resource (e.g., Air Quality Data) and use the generated JWT to attempt access. During this step, a popup will appear, visualizing the request flow through the system architecture (Client -> APISIX -> PAP -> OPA -> Mock Data).
5.  **Step 5: Final Result**: This panel displays the final response from the protected endpoint, indicating whether access was granted or denied, and returning the requested data or an error message.

The dashboard is styled with a permanent dark mode theme for a modern and comfortable user experience.

### Test 1: The "Allowed" Scenario
1.  In **Step 1: Live Policy Editor**, ensure the default policy allows `role: ICT` from `gemeente: Eindhoven` to read resources. If you've modified it, click "Update Policy".
2.  Obtain a JWT from Keycloak using the test user credentials:
    ```bash
    curl -X POST "http://localhost:8081/realms/ODRL-demo/protocol/openid-connect/token" \
      -d "client_id=odrl-app" \
      -d "grant_type=password" \
      -d "username=testuser" \
      -d "password=test" \
      -d "client_secret=Mhj3bFw2HaWr8STaAwscMPnlk1Z9DktN" | jq -r '.access_token'
    ```
3.  In **Step 3: Provide Keycloak JWT**, paste the token into the text area and click **"Use this JWT"**.
4.  In **Step 4: Test Protected Endpoint**, select a resource (e.g., **"Air Quality Data"**).
5.  Click **Test Selected Endpoint**.
6.  **Observe the result:**
    *   **Step 2: Backend Log** will show the step-by-step authorization flow.
    *   **Step 5: Final Result** will display the protected JSON data for the selected resource.
    *   An architecture diagram popup will visualize the successful request flow.

### Test 2: The "Denied" Scenario
1.  Modify the Keycloak user roles or update the ODRL policy to create a mismatch (e.g., change policy to require `role: Finance` instead of `role: ICT`).
2.  Obtain a JWT from Keycloak using the same curl command as above.
3.  In **Step 3: Provide Keycloak JWT**, paste the token into the text area and click **"Use this JWT"**.
4.  In **Step 4: Test Protected Endpoint**, select any data resource.
5.  Click **Test Selected Endpoint**.
6.  **Observe the result:**
    *   **Step 2: Backend Log** will show the `pap` service denying the request.
    *   **Step 5: Final Result** will display an "Access Denied" error.
    *   An architecture diagram popup will visualize the denied request flow.

---

## Manual Testing (CLI)

You can also test the entire workflow directly from your command line using `curl`.

### 1. Obtain a JWT from Keycloak

First, get a token using the test user credentials:

```sh
TOKEN=$(curl -X POST "http://localhost:8081/realms/ODRL-demo/protocol/openid-connect/token" \
  -d "client_id=odrl-app" \
  -d "grant_type=password" \
  -d "username=testuser" \
  -d "password=test" \
  -d "client_secret=Mhj3bFw2HaWr8STaAwscMPnlk1Z9DktN" | jq -r '.access_token')
```

### 2. Test the Protected Endpoint

**Example for Air Quality data (with the obtained token):**
```sh
curl -i http://192.168.2.131:9088/data/airquality -H "Authorization: Bearer $TOKEN"
```

- With the **testuser token** (having `role: ICT` and `gemeente: Eindhoven`), you should receive an `HTTP/1.1 200 OK` response with the protected data in the body.
- With an **invalid token** (or one not matching policy), you should receive an `HTTP/1.1 403 Forbidden` response.

### 3. One-Liner Test Command

For quick testing, you can combine the token acquisition and API call:

```sh
curl -i http://192.168.2.131:9088/data/airquality \
  -H "Authorization: Bearer $(curl -X POST "http://localhost:8081/realms/ODRL-demo/protocol/openid-connect/token" \
  -d "client_id=odrl-app" \
  -d "grant_type=password" \
  -d "username=testuser" \
  -d "password=test" \
  -d "client_secret=Mhj3bFw2HaWr8STaAwscMPnlk1Z9DktN" | jq -r '.access_token')"
```


### Manually Updating ODRL Policies

The Policy Administration Point (PAP) service exposes an endpoint to directly update the ODRL policy that OPA uses for authorization decisions. This can be useful for debugging or integrating with external policy management systems.

To update the policy:

1.  **Prepare your ODRL Policy JSON:** Ensure you have a valid ODRL policy in JSON format. You can use the `policies/eindhoven-ict.json` file as a template or copy the current policy from the "Live Policy Editor" in the web dashboard.

2.  **Send the policy via cURL:** Use the following `curl` command to send your ODRL policy to the PAP service. Remember to adjust the `http://192.168.2.131:9088` address to your actual gateway URL if not running on localhost.

    ```sh
    curl -s -X POST http://192.168.2.131:9088/pap/policies \
    -H "Content-Type: application/json" \
    -d '@your_policy_file.json'
    ```
    Replace `your_policy_file.json` with the path to your ODRL policy file.

    Upon success, the PAP service will process the policy and load it into OPA. You can then test the new policy's effect using the dashboard or manual CLI testing.

---

## Cleanup

To stop and remove all running containers and networks:

```sh
docker compose down
```
