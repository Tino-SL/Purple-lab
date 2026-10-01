#!/usr/bin/env bash
# ingest.sh — upload the newest collection zip into BloodHound CE via its API,
# so you don't have to click through the web UI. Idempotent-ish: each run
# creates a new file-upload job and ingests the newest zip in collections/.
#
#   ./ingest.sh                         # newest zip, default admin creds from .env-ish
#   BH_ADMIN=admin BH_ADMIN_PASS=... ./ingest.sh
set -euo pipefail

BASE="${BH_BASE:-http://127.0.0.1:8080}"
ADMIN="${BH_ADMIN:-admin}"
ADMIN_PASS="${BH_ADMIN_PASS:?set BH_ADMIN_PASS to your BloodHound admin password}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP="$(ls -1t "${SCRIPT_DIR}"/collections/*.zip 2>/dev/null | head -1 || true)"
[ -n "$ZIP" ] || { echo "No zip in collections/ — run ./collect.sh first."; exit 1; }
echo "[*] Ingesting: $(basename "$ZIP")"

# 1. Login -> session JWT
TOKEN="$(curl -fsS -X POST "${BASE}/api/v2/login" \
  -H 'Content-Type: application/json' \
  -d "{\"login_method\":\"secret\",\"username\":\"${ADMIN}\",\"secret\":\"${ADMIN_PASS}\"}" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"]["session_token"])')"
AUTH=(-H "Authorization: Bearer ${TOKEN}")

# 2. Start a file-upload job
JOB="$(curl -fsS -X POST "${BASE}/api/v2/file-upload/start" "${AUTH[@]}" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"]["id"])')"
echo "[*] Upload job id: ${JOB}"

# 3. Upload the zip
curl -fsS -X POST "${BASE}/api/v2/file-upload/${JOB}" "${AUTH[@]}" \
  -H 'Content-Type: application/zip' --data-binary "@${ZIP}" >/dev/null
echo "[*] Zip uploaded"

# 4. End the job -> triggers ingestion
curl -fsS -X POST "${BASE}/api/v2/file-upload/${JOB}/end" "${AUTH[@]}" >/dev/null
echo "[*] Ingestion started. Watch progress under Administration -> File Ingest,"
echo "    or query the graph at ${BASE} once it finishes."
