# =============================================================================
# Kubernetes Base Resources via Terraform
# =============================================================================
# Cria apenas recursos base do Kubernetes:
# - Namespace
# - Registry Secret (para pull de imagens)
#
# Secrets da aplicação são gerenciadas via GitHub Actions (primeira execução)
# ou manualmente via kubectl
# =============================================================================

# Provider Kubernetes - usa o kubeconfig do cluster DOKS
provider "kubernetes" {
  host  = digitalocean_kubernetes_cluster.fishing_map_cluster.endpoint
  token = digitalocean_kubernetes_cluster.fishing_map_cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.fishing_map_cluster.kube_config[0].cluster_ca_certificate
  )
}

# =============================================================================
# Namespace
# =============================================================================

resource "kubernetes_namespace" "fishing_map" {
  metadata {
    name = "fishing-map"
    labels = {
      name        = "fishing-map"
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

# =============================================================================
# Secret para Registry (pull de imagens privadas)
# =============================================================================

resource "kubernetes_secret" "registry_secret" {
  metadata {
    name      = "registry-secret"
    namespace = kubernetes_namespace.fishing_map.metadata[0].name
    labels = {
      app         = "fishing-map"
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.digitalocean.com" = {
          username = var.do_token
          password = var.do_token
          auth     = base64encode("${var.do_token}:${var.do_token}")
        }
      }
    })
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "kubernetes_namespace" {
  description = "Namespace onde os recursos foram criados"
  value       = kubernetes_namespace.fishing_map.metadata[0].name
}

output "registry_secret_name" {
  description = "Nome da Secret do Registry"
  value       = kubernetes_secret.registry_secret.metadata[0].name
}

