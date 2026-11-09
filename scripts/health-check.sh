#!/usr/bin/env bash
# Smoke test: create an item, list items, fetch the item. Exit 1 on any failure.
set -euo pipefail

API="${API_URL:-$(terraform -chdir="$(dirname "$0")/../terraform/envs" output -raw api_url)}"
API="${API%/}"
fail=0

check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS  $name ($actual)"
  else
    echo "FAIL  $name (expected $expected, got $actual)"
    fail=1
  fi
}

# 1. Create
resp=$(curl -s -w '\n%{http_code}' -X POST "$API/items" \
  -H "Content-Type: application/json" -d '{"name":"health-check"}')
code=$(tail -n1 <<<"$resp"); body=$(sed '$d' <<<"$resp")
check "POST /items" 201 "$code"
id=$(python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' <<<"$body" 2>/dev/null || true)

# 2. List
code=$(curl -s -o /dev/null -w '%{http_code}' "$API/items")
check "GET /items" 200 "$code"

# 3. Get one
if [[ -n "$id" ]]; then
  code=$(curl -s -o /dev/null -w '%{http_code}' "$API/items/$id")
  check "GET /items/{id}" 200 "$code"
fi

# 4. Unknown id must be 404
code=$(curl -s -o /dev/null -w '%{http_code}' "$API/items/does-not-exist")
check "GET /items/unknown" 404 "$code"

exit "$fail"
