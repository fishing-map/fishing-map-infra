terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }

  # Backend usando DigitalOcean Spaces (S3-compatible)
  backend "s3" {
    # Configuração fornecida via CLI ou variáveis de ambiente
    # O bucket 'fishing-map-{env}-terraform-state' será criado via Terraform
    #
    # Para inicializar com backend remoto:
    # terraform init \
    #   -backend-config="endpoint=https://nyc3.digitaloceanspaces.com" \
    #   -backend-config="bucket=fishing-map-dev-terraform-state" \
    #   -backend-config="key=terraform.tfstate" \
    #   -backend-config="region=us-east-1" \
    #   -backend-config="skip_credentials_validation=true" \
    #   -backend-config="skip_metadata_api_check=true"
  }
}

provider "digitalocean" {
  token = var.do_token
}
