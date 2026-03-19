# Lessons Learned

- Give the initial prompt a bit more of your own plan
  - Details about networks (names, namely - and bridge types, VLANs, domains, etc so I don't have to go back and move things around)
  - If any workloads should be included in a single Compose file (eg Pihole/PowerDNS so PDNS can wait for PiHole to start).  Claude did this already but I'm surprised more than expectant.
  - Compose file rules (restart policy should be unless-stopped, environmental variables file mounted for configuration instead of hard-coding into the Compose file, don't use named volumes use path mounts under /opt/workdir/, etc)
- Add prompt to ensure services are loaded into Homepage config, or have Homepage use the Docker Socket for label based adding
- Dive deeper into some needs for services (eg Add the configuration to Netboot.xyz for the latest Ubuntu, Fedora, RHEL, and Talos boot images)
- Add Host-level things (eg initial OS setup, Node Exporter, dnf-automatic, etc)