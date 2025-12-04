#!/bin/bash

# A script to initialize the APISIX configuration for the ODRL demo.
# This script is idempotent, meaning it can be run multiple times without causing errors.

set -e

ADMIN_URL="http://localhost:9180/apisix/admin"
API_KEY="edd1c9f034335f136f87ad84b625c8f1"
GATEWAY_URL="http://localhost:9088"

echo "Waiting for APISIX Admin API to be ready..."
until curl -s -o /dev/null -w "%{http_code}" "$ADMIN_URL/routes" -H "X-API-KEY: $API_KEY" | grep -q 200; do
  echo -n "."
  sleep 1
done
echo -e "\nAPISIX is ready."

echo -e "\n[0/5] Deleting existing consumer 'paradym-user' (if it exists)..."
curl -s -X DELETE "$ADMIN_URL/consumers/paradym-user" -H "X-API-KEY: $API_KEY" || true # Use || true to prevent script from exiting if consumer doesn't exist

echo -e "\n[1/5] Creating upstreams..."
curl -s "$ADMIN_URL/upstreams/mock-data-upstream" -H "X-API-KEY: $API_KEY" -X PUT -d '
{
  "name": "mock-data-service",
  "nodes": {
    "mock-data:80": 1
  }
}'

curl -s "$ADMIN_URL/upstreams/pap-service-upstream" -H "X-API-KEY: $API_KEY" -X PUT -d '
{
  "name": "pap-service-upstream",
  "nodes": {
    "pap:3000": 1
  }
}'

echo -e "\n[2/5] Configuring data route for Keycloak..."
# Route for the protected data endpoint (OPTIONS for CORS preflight)
curl -s "$ADMIN_URL/routes/data-route-options" -H "X-API-KEY: $API_KEY" -X PUT -d '
{
    "name": "data-route-options",
    "uris": ["/data/*"],
    "methods": ["OPTIONS"],
    "priority": 1,
    "plugins": {
        "cors": {
            "allow_origins": "*",
            "allow_methods": "*",
            "allow_headers": "*"
        }
    }
}'

# Route for the protected data endpoint (GET), now secured by Keycloak
curl -s "$ADMIN_URL/routes/data-route" -H "X-API-KEY: $API_KEY" -X PUT -d '
{
    "name": "data-route",
    "uris": ["/data/*"],
    "methods": ["GET"],
    "upstream_id": "pap-service-upstream",
    "plugins": {
        "cors": {
            "allow_origins": "*",
            "allow_methods": "*",
            "allow_headers": "*"
        }
    }
}'

# Route for the PAP service (JWT generation and policy upload)
curl -s "$ADMIN_URL/routes/pap-route" -H "X-API-KEY: $API_KEY" -X PUT -d '
{
    "name": "pap-route",
    "uris": ["/pap/*"],
    "methods": ["GET", "POST", "OPTIONS"],
    "upstream_id": "pap-service-upstream",
    "plugins": {
        "cors": {
            "allow_origins": "*",
            "allow_methods": "*",
            "allow_headers": "*"
        },
        "proxy-rewrite": {
            "regex_uri": ["^/pap/(.*)", "/$1"]
        }
    }
}'

# Allow the frontend to be served through the gateway as well to avoid all CORS issues
# First, create an upstream for it
curl -s "$ADMIN_URL/upstreams/frontend-upstream" -H "X-API-KEY: $API_KEY" -X PUT -d '
{
  "name": "frontend-service",
  "nodes": {
    "frontend:80": 1
  }
}'
# Then, create a route for it
curl -s "$ADMIN_URL/routes/frontend-route" -H "X-API-KEY: $API_KEY" -X PUT -d '
{
    "name": "frontend-route",
    "uri": "/*",
    "priority": -10,
    "upstream_id": "frontend-upstream"
}'


echo -e "\n[5/5] Pushing ODRL policy to OPA via PAP service..."
# It might take a moment for the routes to become active
sleep 2 
curl -s "$GATEWAY_URL/pap/policies" -H "Content-Type: application/json" -d '@policies/eindhoven-ict.json'

echo -e "\n\nInitialization complete!"
echo "You can now access the dashboard at http://localhost:9088 (via APISIX)"
