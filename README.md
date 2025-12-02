# ODRL-based Authorization Prototype

This project demonstrates a complete, end-to-end workflow for ODRL-based authorization in a modern data space architecture. It uses APISIX as an API Gateway, Open Policy Agent (OPA) as a policy decision point, and a custom Node.js service as a Policy Administration Point (PAP).

The flow is as follows:
1.  A user requests a JSON Web Token (JWT) from the PAP service, providing their credentials.
2.  The user presents this JWT to the APISIX gateway to access a protected data resource.
3.  APISIX validates the JWT.
4.  The PAP service receives the request, queries OPA with the user's attributes from the JWT to get an authorization decision.
5.  If OPA allows the request, the PAP service proxies the request to the `mock-data` service, which returns the protected data.

---

## 🏛️ Architecture

This environment is composed of several microservices orchestrated by `docker-compose.yml`:

- **APISIX (`:9088`)**: The API Gateway and the single entry point for all traffic. It is responsible for:
  - Serving the frontend dashboard (`/`).
  - Validating JSON Web Tokens (JWTs) using the `jwt-auth` plugin.
  - Proxying requests to the appropriate backend services (`/pap/*` to the PAP, `/data/test` to the PAP).

- **PAP (Policy Administration Point)**: A custom Node.js service responsible for:
  - Generating JWTs for clients (`/auth/token`).
  - Receiving ODRL policies and translating them into OPA's Rego language (`/policies`).
  - Handling requests for protected data (`/data/test`), where it queries OPA for an authorization decision before proxying to the `mock-data` service.

- **OPA (Open Policy Agent) (`:8181`)**: The policy decision point. It runs as a standalone server and makes authorization decisions based on the Rego policies loaded by the PAP.

- **etcd**: A key-value store that holds all of APISIX's dynamic configuration (routes, consumers, etc.).

- **Mock Data**: An NGINX server that hosts the static `data.json` file, representing the protected resource.

- **Frontend**: An NGINX server that hosts the `index.html` dashboard (served via APISIX).

---

## Prerequisites

- Docker
- Docker Compose

---

## 🚀 Quick Start

Getting the environment running is a simple two-step process.

### 1. Start the Services

Build and start all the services in the background:

```sh
docker compose up -d --build
```

### 2. Initialize the Configuration

After the services have started, run the initialization script. This will automatically configure APISIX (routes, consumers, upstreams) and push the initial policy to OPA.

```sh
./init-apisix.sh
```

Wait for the script to complete. You should see "Initialization complete!" at the end.

---

## 🧪 Usage and Testing

The entire system can now be tested using the interactive web dashboard. The script automatically configured APISIX to serve the dashboard.

**Access the dashboard here:** [http://localhost:9088](http://localhost:9088)

### Test 1: The "Allowed" Scenario
1.  Make sure the dropdown is set to **"Valid User (role: ICT, gemeente: Eindhoven)"**.
2.  Click **Get JWT**.
3.  Click **Test /data/test**.
4.  **Observe the result:** The "Backend Log" will show the step-by-step flow, and the "Final Result" will show the protected JSON data.

### Test 2: The "Denied" Scenario
1.  Change the dropdown to **"Invalid User (role: Finance, gemeente: Eindhoven)"**.
2.  Click **Get JWT**.
3.  Click **Test /data/test**.
4.  **Observe the result:** The "Backend Log" will show OPA returning a `DENY` decision, and the "Final Result" will show an "Access Denied" error.

---

## 👨‍💻 Manual Testing (CLI)

You can also test the entire workflow directly from your command line using `curl`. This is useful for debugging or scripting.

### 1. Get a JWT

**For a valid user (`role: "ICT"`):**
```sh
curl -s -X POST http://localhost:9088/pap/auth/token \
-H "Content-Type: application/json" \
-d '{"credentials":[{"presentedAttributes":{"role":"ICT","gemeente":"Eindhoven"}}]}'
```

**For an invalid user (`role: "Finance"`):**
```sh
curl -s -X POST http://localhost:9088/pap/auth/token \
-H "Content-Type: application/json" \
-d '{"credentials":[{"presentedAttributes":{"role":"Finance","gemeente":"Eindhoven"}}]}'
```
This will return a JSON object with a token. Copy the token value for the next step.

### 2. Test the Protected Endpoint

Replace `[PASTE_YOUR_TOKEN_HERE]` with the token you just copied and run the command:

```sh
TOKEN="[PASTE_YOUR_TOKEN_HERE]"
curl -i http://localhost:9088/data/test -H "Authorization: Bearer $TOKEN"
```

- With the **valid** token, you should receive an `HTTP/1.1 200 OK` response with the protected `data.json` in the body.
- With the **invalid** token, you should receive an `HTTP/1.1 403 Forbidden` response with an "Access Denied" message.

---

## 🧹 Cleanup

To stop and remove all running containers and networks:

```sh
docker compose down
```