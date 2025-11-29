# ===========================================
# Managed PostgreSQL Database (Production)
# ===========================================

resource "digitalocean_database_cluster" "fishing_map_db" {
  count = var.enable_managed_database ? 1 : 0

  name       = "${var.project_name}-${var.environment}-db"
  engine     = "pg"
  version    = "15"
  size       = var.database_size
  region     = var.cluster_region
  node_count = 1

  tags = [
    var.project_name,
    var.environment,
    "database",
    "postgresql"
  ]
}

# Database firewall rule to allow Kubernetes cluster access
resource "digitalocean_database_firewall" "fishing_map_db_firewall" {
  count      = var.enable_managed_database ? 1 : 0
  cluster_id = digitalocean_database_cluster.fishing_map_db[0].id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.fishing_map_cluster.id
  }
}

# Create fishing_map database
resource "digitalocean_database_db" "fishing_map_database" {
  count      = var.enable_managed_database ? 1 : 0
  cluster_id = digitalocean_database_cluster.fishing_map_db[0].id
  name       = "fishing_map"
}

# Create database user
resource "digitalocean_database_user" "fishing_map_user" {
  count      = var.enable_managed_database ? 1 : 0
  cluster_id = digitalocean_database_cluster.fishing_map_db[0].id
  name       = "fishing_user"
}
