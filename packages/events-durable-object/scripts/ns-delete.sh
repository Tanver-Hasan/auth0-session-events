#! /bin/bash
set -euo pipefail

# Required tools.
if ! which curl >/dev/null; then
  echo "$0: Please install curl" >&2
  exit 1
fi
if ! which jq >/dev/null; then
  echo "$0: Please install jq" >&2
  exit 1
fi

# The .env file will contail the credentials we used to connect to the API.
if [ -e .env ]; then
  source .env
else
  echo -n "Please create a .env file"
  return 1
fi

# Helper to call the cloudflare API.
api() {
  RESULT=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID$@")
  if [ $(echo "$RESULT" | jq .success) = true ]; then
    printf "$RESULT" | jq .result
    return 0
  else
    printf "\nAPI Error: " >&2
    printf "$RESULT" | jq >&2
    return 1
  fi
}

# Test credentials.
printf "\n"
printf "[+] Checking if credentials can access Durable Objects...\n"
api /workers/scripts > /dev/null
api /workers/durable_objects/namespaces > /dev/null
printf "[+] Credentials OK!\n"

printf "[+] Deleting namespace $NAMESPACE_ID...\n"
api /workers/durable_objects/namespaces/$NAMESPACE_ID \
    -X DELETE > /dev/null
printf "[+] Done\n"