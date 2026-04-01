ui = true
disable_mlock = true

storage "raft" {
  path    = "/vault/data"
  node_id = "vault-1"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 1
}

api_addr     = "https://vault.lab.kemo.dev"
cluster_addr = "https://vault.lab.kemo.dev:8201"

log_level = "info"
