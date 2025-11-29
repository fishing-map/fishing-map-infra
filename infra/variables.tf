# DigitalOcean Token
variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

# Project configuration
variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "fishing-map"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Droplet configuration
variable "droplet_size" {
  description = "Tamanho do droplet"
  type        = string
  default     = "s-2vcpu-4gb" # 2 vCPUs, 4GB RAM, 80GB SSD
}

variable "droplet_region" {
  description = "Região do droplet"
  type        = string
  default     = "sao1" # São Paulo, Brazil
}

variable "droplet_image" {
  description = "Imagem do droplet"
  type        = string
  default     = "ubuntu-22-04-x64"
}

# SSH Key
variable "ssh_public_key_path" {
  description = "Caminho para a chave SSH pública"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Domain configuration
variable "domain_name" {
  description = "Nome do domínio"
  type        = string
  default     = ""
}

# Database configuration
variable "enable_managed_database" {
  description = "Habilitar banco de dados gerenciado"
  type        = bool
  default     = false
}

variable "database_size" {
  description = "Tamanho do banco gerenciado"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

# Backup configuration
variable "enable_backups" {
  description = "Habilitar backups automáticos"
  type        = bool
  default     = true
}
variable "vpc_cidr" {
  type    = string
  default = "10.80.0.0/16"
}

# Two public and two private subnets for EKS (across 2 AZs)
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.80.10.0/24", "10.80.11.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.80.20.0/24", "10.80.21.0/24"]
}

# Tags
variable "tags" {
  type    = map(string)
  default = { project = "eks" }
}

# Spaces (Object Storage S3-compatible)
variable "spaces_region" {
  description = "Região do DigitalOcean Spaces (nyc3, ams3, sfo3, sgp1)"
  type        = string
  default     = "nyc3" # Mais próximo do Brasil: sfo3 ou nyc3
}

variable "enable_spaces_cdn" {
  description = "Habilitar CDN para o bucket de assets"
  type        = bool
  default     = true
}
