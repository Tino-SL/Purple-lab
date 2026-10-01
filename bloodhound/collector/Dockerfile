# NetExec-based BloodHound CE collector for the lab.
# nxc seals/signs LDAP over 389, so it works against the signing-enforced
# Server 2025 DC WITHOUT needing LDAPS — unlike bloodhound-python, which
# falls back to LDAPS. Built on Kali because the Debian netexec package
# pulls clean (aardwolf/netifaces build fine there, unlike python:slim).
FROM kalilinux/kali-rolling:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends netexec python3-pip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# nxc ships with the legacy 'bloodhound' package but its config defaults to
# BloodHound-CE output; swap in the CE library so --bloodhound emits a
# CE-format zip that this stack can ingest.
RUN pip3 install --quiet --break-system-packages bloodhound-ce \
    && pip3 uninstall -y -q bloodhound || true

WORKDIR /out
ENTRYPOINT ["nxc"]
