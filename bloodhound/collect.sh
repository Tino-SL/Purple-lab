#!/usr/bin/env bash
# collect.sh — run BloodHound CE collection against the lab DC from a container.
#
# Uses the lab-bh-collector image (NetExec). nxc signs/seals LDAP over 389, so
# it works against the signing-enforced Server 2025 DC without LDAPS. Output is
# a CE-format zip dropped in ./collections/, ready to upload to the CE web UI
# (http://127.0.0.1:8080 -> Administration -> File Ingest -> Upload).
#
# Usage:
#   ./collect.sh                 # defaults below (vagrant/vagrant @ lab.local)
#   DC_IP=192.168.100.10 DOMAIN=lab.local BH_USER=vagrant BH_PASS=vagrant ./collect.sh
set -euo pipefail

DC_IP="${DC_IP:-192.168.100.10}"
DC_FQDN="${DC_FQDN:-win-jmd7ec5nqo9.lab.local}"
DOMAIN="${DOMAIN:-lab.local}"
BH_USER="${BH_USER:-vagrant}"
BH_PASS="${BH_PASS:-vagrant}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/collections"
mkdir -p "$OUT_DIR"

echo "[*] Collecting from ${DC_IP} (${DOMAIN}) as ${BH_USER} ..."
docker run --rm \
  --network host \
  --dns "$DC_IP" \
  --add-host "${DC_FQDN}:${DC_IP}" \
  -v "${OUT_DIR}:/root/.nxc/logs" \
  lab-bh-collector:latest \
  ldap "$DC_IP" -u "$BH_USER" -p "$BH_PASS" \
  --bloodhound -c All --dns-server "$DC_IP"

echo
echo "[*] Newest collection zip:"
ls -1t "${OUT_DIR}"/*.zip 2>/dev/null | head -1 || echo "  (no zip produced — check output above)"
echo "[*] Upload it at http://127.0.0.1:8080  (Administration -> File Ingest)."
