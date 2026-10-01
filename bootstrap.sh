#!/usr/bin/env bash
#
# bootstrap.sh — bring the WHOLE lab up from cold, in the correct order.
#
#   1. vagrant up dc01            (must be a DC before anyone can join)
#   2. vagrant up srv01 client01  (domain members)
#   3. vagrant up kali1           (attacker box, optional — no Ansible)
#   4. ansible-playbook ping.yml  (confirm WinRM is answering)
#   5. ansible-playbook site.yml  (promote -> join -> create users -> pw policy)
#   6. ansible-playbook sysmon.yml + honeypots.yml   (monitoring/detection)
#   7. ansible-playbook enable_ldaps.yml             (LDAPS, for BloodHound)
#
# After this finishes the lab is fully built AND instrumented: the domain
# exists, Sysmon + the honeypot tripwires are deployed, and LDAPS is on so the
# Dockerized BloodHound collector (see bloodhound/) can pull the graph.
#
# Usage:
#   ./bootstrap.sh                  full build (everything above)
#   ./bootstrap.sh --no-kali        skip the Kali attacker box
#   ./bootstrap.sh --no-monitoring  build the domain only (skip step 6)
#   ./bootstrap.sh --no-ldaps       skip LDAPS (skip step 7)
#   ./bootstrap.sh --ansible        skip vagrant, just (re)run ALL the playbooks

set -euo pipefail

# Always operate from the project root, regardless of where we're called from.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"

WITH_KALI=1
WITH_MONITORING=1
WITH_LDAPS=1
ANSIBLE_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --no-kali)        WITH_KALI=0 ;;
    --no-monitoring)  WITH_MONITORING=0 ;;
    --no-ldaps)       WITH_LDAPS=0 ;;
    --ansible)        ANSIBLE_ONLY=1 ;;
    -h|--help)
      # print the leading comment block (skip shebang, stop at first code line)
      awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# Run a playbook from the ansible dir, aborting the whole build if it fails.
run_playbook() {
  local pb="$1"
  log "ansible-playbook ${pb}"
  ansible-playbook "$pb"
}

if [[ "$ANSIBLE_ONLY" -eq 0 ]]; then
  cd "$PROJECT_ROOT"

  log "Bringing up dc01 (domain controller first)"
  vagrant up dc01

  log "Bringing up domain members: srv01, client01"
  vagrant up srv01 client01

  if [[ "$WITH_KALI" -eq 1 ]]; then
    log "Bringing up kali1 (attacker box)"
    vagrant up kali1
  else
    log "Skipping kali1 (--no-kali)"
  fi
fi

cd "$ANSIBLE_DIR"

log "Checking WinRM connectivity to all Windows hosts"
if ! ansible-playbook ping.yml; then
  echo "WinRM ping failed — hosts may still be booting. Aborting before site.yml." >&2
  exit 1
fi

log "Running full lab build: promote DC -> join members -> create users -> pw policy"
run_playbook site.yml

if [[ "$WITH_MONITORING" -eq 1 ]]; then
  log "Deploying monitoring: Sysmon + honeypot tripwires"
  run_playbook sysmon.yml
  run_playbook honeypots.yml
else
  log "Skipping monitoring (--no-monitoring)"
fi

if [[ "$WITH_LDAPS" -eq 1 ]]; then
  log "Enabling LDAPS on the DC (for BloodHound collection)"
  run_playbook enable_ldaps.yml
else
  log "Skipping LDAPS (--no-ldaps)"
fi

log "Done. Lab is up, configured, and instrumented."
echo "  - Domain:      lab.local (dc01 .10, srv01 .20, client01 .30, kali1 .40)"
[[ "$WITH_MONITORING" -eq 1 ]] && echo "  - Monitoring:  Sysmon + honeypots deployed (watch with honey_detect.yml)"
[[ "$WITH_LDAPS" -eq 1 ]]      && echo "  - BloodHound:  LDAPS on; collect with bloodhound/collect.sh"
