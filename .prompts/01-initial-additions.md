# INPUT

> [Commit 3aa824f](https://github.com/kenmoini/kemo-labs/commit/3aa824f88bdf6f3fdd40d6a76fd0028d2cf2ecae)

I like some of those suggestions - let's add WUD (getwud.github.io/wud/) since Watchtower is no longer maintained.  Let's also add Ntfy and Semaphore UI.

- Use an agent team to review and research the list and create a Planing document in each workload's folder.
- Determine if any other key workloads are missing and suggest them.
- Reorder the workload deployment strategy to meet dependencies some may have on others and make an overall Planning document.
- Use an agent team to create the deployment files, manifests, and scripts needed to deploy the ensemble.  Use Docker Compose whenever possible, VMs when needed. Talos Kubernetes is for other workloads not listed here.
- Write the documentation to support the workloads.
- Ask me any questions to clarify

# OUTPUT

3 New Workloads Added

```
┌────────────────────────┬───────────────┬──────────────────────────┬───────────────────────────────────────────────────────────┐
│        Workload        │      IP       │         Category         │                           Files                           │
├────────────────────────┼───────────────┼──────────────────────────┼───────────────────────────────────────────────────────────┤
│ WUD (What's Up Docker) │ 192.168.42.9  │ infrastructure/wud       │ PLANNING.md, docker-compose.yml, .env.example, README.md  │
├────────────────────────┼───────────────┼──────────────────────────┼───────────────────────────────────────────────────────────┤
│ Ntfy (Push             │ 192.168.42.82 │ communication/ntfy       │ PLANNING.md, docker-compose.yml, .env.example,            │
│ Notifications)         │               │                          │ server.yml, README.md                                     │
├────────────────────────┼───────────────┼──────────────────────────┼───────────────────────────────────────────────────────────┤
│ Semaphore (Ansible UI) │ 192.168.42.25 │ infrastructure/semaphore │ PLANNING.md, docker-compose.yml, .env.example, README.md  │
└────────────────────────┴───────────────┴──────────────────────────┴───────────────────────────────────────────────────────────┘
```

Integration points updated:
- PostgreSQL init script: added semaphore database + user
- Databases .env.example: added PG_SEMAPHORE_PASSWORD
- deploy.sh: Ntfy added to Phase 9, WUD + Semaphore added to Phase 10
- Master PLANNING.md: IP allocation, dependency graph, deployment phases, resource estimates all updated
- Removed WUD/Ntfy/Semaphore from "Suggested" list (now deployed)

Updated totals: 203 files, 37 workloads, 37 docker-compose stacks

---

# INPUT

Update the main README.md file with the new additions too

# OUTPUT

README.md is now updated with all 3 new workloads. The changes include:

- Container count: 84 -> 87
- Architecture diagram: Ntfy in Phase 9, WUD + Semaphore in Phase 10
- Directory structure: added to infrastructure and communication
- IP allocation: .9 (WUD), .15-.19 (expanded DB IPs), .25 (Semaphore), .82 (Ntfy)
- Deployment phases: Phase 9 and 10 updated
- Key URLs: 3 new entries
- Resource notes: updated to ~106 GB