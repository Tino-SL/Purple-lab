# BloodHound CE (Dockerized) for the lab

Containerized BloodHound Community Edition for analyzing the AD attack surface
of this lab, plus a container-based collector. This is what Docker is *for* in
this project — no BloodHound tooling is installed on the host or on Kali; it all
runs in containers.

## Why containers (and why not bloodhound-python)

The DC (`dc01`, Server 2025) enforces LDAP signing. The classic
`bloodhound-python` / `bloodhound-ce-python` collectors do an unsigned simple
bind on 389, get refused, fall back to LDAPS on 636, and fail. NetExec (`nxc`)
signs/seals its LDAP connection over 389, so it collects successfully without
LDAPS. We run `nxc` from a purpose-built container (`collector/Dockerfile`) so
the messy Python/BloodHound-CE dependency mix never touches the host.

(An `ansible/enable_ldaps.yml` playbook also exists and gives the DC a
self-signed LDAPS cert — useful for other LDAPS clients — but the container
collector below does not need it.)

## Layout

    bloodhound/
      docker-compose.yml   official SpecterOps CE stack (app + Postgres + Neo4j)
      .env                 stack config (ports, DB creds) — lab values
      collector/Dockerfile NetExec-based collector image (lab-bh-collector)
      collect.sh           run collection -> drops a CE zip in collections/
      collections/         collected zips (gitignored content)

## 1. Start the BloodHound CE web app

    cd bloodhound
    docker compose up -d

Wait ~30s for the databases to go healthy, then open:

    http://127.0.0.1:8080

First login uses the admin account:

    admin / Password123!

(The auto-generated initial password from the app log was rotated to this.)

## 2. Build the collector image (one time)

    docker build -t lab-bh-collector:latest collector/

## 3. Collect from the DC

    ./collect.sh

Defaults to `vagrant:vagrant @ lab.local` against `192.168.100.10`. Override via
env vars:

    DC_IP=192.168.100.10 DOMAIN=lab.local BH_USER=vagrant BH_PASS=vagrant ./collect.sh

It writes a CE-format zip into `collections/`.

## 4. Ingest

In the web UI: Administration -> File Ingest -> Upload File, and select the zip
from `collections/`. After ingest completes, run queries / pathfinding against
the lab (e.g. find paths to Domain Admins, or mark the honey accounts as owned
and see what they expose).

## Stop / reset

    docker compose down            # stop, keep data
    docker compose down -v         # stop and wipe the graph + app DBs
