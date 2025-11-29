# Kubernetes Cluster information
output "cluster_id" {
  description = "ID do cluster Kubernetes"
  value       = digitalocean_kubernetes_cluster.fishing_map_cluster.id
}

output "cluster_name" {
  description = "Nome do cluster"
  value       = digitalocean_kubernetes_cluster.fishing_map_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster"
  value       = digitalocean_kubernetes_cluster.fishing_map_cluster.endpoint
  sensitive   = true
}

output "cluster_region" {
  description = "Região do cluster"
  value       = digitalocean_kubernetes_cluster.fishing_map_cluster.region
}

output "cluster_version" {
  description = "Versão do Kubernetes"
  value       = digitalocean_kubernetes_cluster.fishing_map_cluster.version
}

output "cluster_status" {
  description = "Status do cluster"
  value       = digitalocean_kubernetes_cluster.fishing_map_cluster.status
}

# Node Pool information
output "node_pool_size" {
  description = "Tamanho dos nodes"
  value       = var.node_pool_size
}

output "node_pool_count" {
  description = "Quantidade atual de nodes"
  value       = var.node_pool_count
}

# Container Registry
output "registry_name" {
  description = "Nome do Container Registry"
  value       = digitalocean_container_registry.fishing_map_registry.name
}

output "registry_endpoint" {
  description = "Endpoint do Container Registry"
  value       = digitalocean_container_registry.fishing_map_registry.server_url
}

# Project information
output "project_id" {
  description = "ID do projeto no DigitalOcean"
  value       = digitalocean_project.fishing_map.id
}

output "project_name" {
  description = "Nome do projeto"
  value       = digitalocean_project.fishing_map.name
}

# Domain information
output "domain_name" {
  description = "Nome do domínio configurado"
  value       = var.domain_name != "" ? var.domain_name : "Nenhum domínio configurado"
}

# Load Balancer (if enabled)
output "load_balancer_ip" {
  description = "IP do Load Balancer"
  value       = var.enable_load_balancer ? digitalocean_loadbalancer.fishing_map_lb[0].ip : "Load Balancer não habilitado"
}

# Kubeconfig command
output "kubeconfig_command" {
  description = "Comando para configurar kubectl"
  value       = "doctl kubernetes cluster kubeconfig save ${digitalocean_kubernetes_cluster.fishing_map_cluster.name}"
}

# Database information (Managed PostgreSQL)
output "database_host" {
  description = "Host do banco de dados managed"
  value       = var.enable_managed_database ? digitalocean_database_cluster.fishing_map_db[0].host : ""
  sensitive   = true
}

output "database_port" {
  description = "Porta do banco de dados managed"
  value       = var.enable_managed_database ? digitalocean_database_cluster.fishing_map_db[0].port : 25060
}

output "database_name" {
  description = "Nome do banco de dados"
  value       = var.enable_managed_database ? digitalocean_database_db.fishing_map_database[0].name : "fishing_map"
}

output "database_user" {
  description = "Usuário do banco de dados"
  value       = var.enable_managed_database ? digitalocean_database_cluster.fishing_map_db[0].user : "doadmin"
  sensitive   = true
}

output "database_password" {
  description = "Senha do banco de dados"
  value       = var.enable_managed_database ? digitalocean_database_cluster.fishing_map_db[0].password : ""
  sensitive   = true
}

output "database_uri" {
  description = "Connection string completa do banco"
  value       = var.enable_managed_database ? digitalocean_database_cluster.fishing_map_db[0].uri : ""
  sensitive   = true
}

# DigitalOcean Spaces (Object Storage)
output "spaces_backend_bucket_name" {
  description = "Nome do bucket de backend (Terraform state)"
  value       = digitalocean_spaces_bucket.terraform_state.name
}

output "spaces_backend_bucket_endpoint" {
  description = "Endpoint do bucket de backend"
  value       = "https://${digitalocean_spaces_bucket.terraform_state.bucket_domain_name}"
}

output "spaces_assets_bucket_name" {
  description = "Nome do bucket de assets da aplicação"
  value       = digitalocean_spaces_bucket.application_assets.name
}

output "spaces_assets_bucket_endpoint" {
  description = "Endpoint do bucket de assets"
  value       = "https://${digitalocean_spaces_bucket.application_assets.bucket_domain_name}"
}

output "spaces_assets_cdn_endpoint" {
  description = "Endpoint do CDN para assets"
  value       = "https://${digitalocean_cdn.application_assets_cdn.endpoint}"
}

output "spaces_assets_bucket_region" {
  description = "Região dos Spaces"
  value       = var.spaces_region
}

# Instruções para configurar backend remoto
output "terraform_backend_config" {
  description = "Configuração do backend remoto do Terraform"
  value = <<-EOT
    Para migrar o backend local para o Spaces, adicione no main.tf:

    terraform {
      backend "s3" {
        endpoint                    = "https://${var.spaces_region}.digitaloceanspaces.com"
        key                         = "fishing-map/${var.environment}/terraform.tfstate"
        bucket                      = "${digitalocean_spaces_bucket.terraform_state.name}"
        region                      = "us-east-1" # Fixo para compatibilidade S3
        skip_credentials_validation = true
        skip_metadata_api_check     = true
      }
    }

    E configure as credenciais:
    export AWS_ACCESS_KEY_ID="<your-spaces-access-key>"
    export AWS_SECRET_ACCESS_KEY="<your-spaces-secret-key>"
  EOT
}

# Deployment instructions
output "deployment_instructions" {
  description = "Instruções para deploy"
  value = <<-EOT
    1. Configure doctl: doctl auth init
    2. Configure kubectl: ${digitalocean_kubernetes_cluster.fishing_map_cluster.name != "" ? "doctl kubernetes cluster kubeconfig save ${digitalocean_kubernetes_cluster.fishing_map_cluster.name}" : "cluster não encontrado"}
    3. Verify connection: kubectl get nodes
    4. Deploy manifests: kubectl apply -f k8s/
    5. Check pods: kubectl get pods -A
    6. Get LoadBalancer IP: kubectl get svc -o wide
  EOT
}
