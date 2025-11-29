# DigitalOcean Token
variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

# Nome do bucket
variable "bucket_name" {
  description = "Nome do bucket para Terraform state"
  type        = string
  default     = "fishing-map-prod-terraform-state"
}

# Região do Spaces
variable "spaces_region" {
  description = "Região do DigitalOcean Spaces"
  type        = string
  default     = "nyc3"
}

# Spaces Access Key
variable "spaces_access_key" {
  description = "DigitalOcean Spaces Access Key"
  type        = string
  sensitive   = true
}

# Spaces Secret Key
variable "spaces_secret_key" {
  description = "DigitalOcean Spaces Secret Key"
  type        = string
  sensitive   = true
}

