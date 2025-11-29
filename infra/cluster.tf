# DigitalOcean Kubernetes Cluster
resource "digitalocean_kubernetes_cluster" "fishing_map_cluster" {
  name    = "${var.project_name}-${var.environment}-cluster"
  region  = var.cluster_region
  version = var.kubernetes_version

  node_pool {
    name       = "${var.project_name}-${var.environment}-pool"
    size       = var.node_pool_size
    auto_scale = true
    min_nodes  = var.node_pool_min_nodes
    max_nodes  = var.node_pool_max_nodes
    tags       = ["${var.project_name}", "${var.environment}", "k8s-node"]
  }

  tags = ["${var.project_name}", "${var.environment}", "kubernetes"]
}

# Container Registry
resource "digitalocean_container_registry" "fishing_map_registry" {
  name                   = "${var.project_name}-${var.environment}"
  subscription_tier_slug = "basic"
  region                 = var.cluster_region
}

# Project
resource "digitalocean_project" "fishing_map" {
  name        = "${var.project_name}-${var.environment}"
  description = "FishingMap Kubernetes Infrastructure"
  purpose     = "Web Application"
  # DigitalOcean aceita apenas: development, staging, production
  # Mapeia 'prod' -> 'production', 'dev' -> 'development'
  environment = var.environment == "prod" ? "production" : (var.environment == "dev" ? "development" : var.environment)

  resources = [
    digitalocean_kubernetes_cluster.fishing_map_cluster.urn
  ]
}
