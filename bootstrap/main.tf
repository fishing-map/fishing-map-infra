# ===========================================
# Terraform Bootstrap - Criar Bucket de State
# ===========================================
# Execute este projeto PRIMEIRO, localmente
# Ele cria o bucket Spaces que será usado como backend
# ===========================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  # Backend local (só para este bootstrap)
  # Este projeto roda uma vez e pronto
}

# Provider DigitalOcean
provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_key
  spaces_secret_key = var.spaces_secret_key
}

# Bucket para Terraform State (backend remoto)
resource "digitalocean_spaces_bucket" "terraform_state" {
  name   = var.bucket_name
  region = var.spaces_region
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Output
output "bucket_name" {
  description = "Nome do bucket criado"
  value       = digitalocean_spaces_bucket.terraform_state.name
}

output "bucket_endpoint" {
  description = "Endpoint do bucket"
  value       = "https://${digitalocean_spaces_bucket.terraform_state.bucket_domain_name}"
}

output "spaces_endpoint" {
  description = "Endpoint do Spaces (para configurar no Terraform)"
  value       = "https://${var.spaces_region}.digitaloceanspaces.com"
}

output "next_steps" {
  description = "Próximos passos"
  value = <<-EOT
    ✅ Bucket criado com sucesso!

    Configuração para usar no main.tf:

    backend "s3" {
      endpoint                    = "https://${var.spaces_region}.digitaloceanspaces.com"
      bucket                      = "${var.bucket_name}"
      key                         = "terraform.tfstate"
      region                      = "us-east-1"
      skip_credentials_validation = true
      skip_metadata_api_check     = true
      skip_requesting_account_id  = true
    }

    Variáveis de ambiente:
    export AWS_ACCESS_KEY_ID="<SPACES_ACCESS_KEY>"
    export AWS_SECRET_ACCESS_KEY="<SPACES_SECRET_KEY>"
  EOT
}
