ui = true
disable_mlock = true

api_addr     = "https://vault.lab.kemo.dev"
cluster_addr = "https://vault.lab.kemo.dev:8201"

log_level = "info"

storage "raft" {
  path    = "/vault/raft/data"
  node_id = "vault-1"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 1
}

telemetry {
  prometheus_retention_time = "12h"
  disable_hostname = true
}
