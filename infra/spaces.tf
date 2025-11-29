
resource "digitalocean_spaces_bucket" "terraform_state" {
  name   = "${var.project_name}-${var.environment}-terraform-state"
  region = var.spaces_region
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_spaces_bucket" "application_assets" {
  name   = "${var.project_name}-${var.environment}-assets"
  region = var.spaces_region
  acl    = "public-read"
}

resource "digitalocean_spaces_bucket_cors_configuration" "application_assets_cors" {
  bucket = digitalocean_spaces_bucket.application_assets.id
  region = var.spaces_region

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = [
      "https://fishingmap.com.br",
      "https://www.fishingmap.com.br",
      "https://app.fishingmap.com.br",
      "http://localhost:3000"
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "digitalocean_cdn" "application_assets_cdn" {
  origin = digitalocean_spaces_bucket.application_assets.bucket_domain_name
  ttl    = 3600 # Cache de 1 hora
}

resource "digitalocean_spaces_bucket_object" "readme" {
  region  = var.spaces_region
  bucket  = digitalocean_spaces_bucket.application_assets.name
  key     = "README.txt"
  acl     = "public-read"
  content = <<-EOT
    FishingMap - Application Assets

    Estrutura de pastas:
    /avatars/     - Fotos de perfil dos usuários
    /captures/    - Fotos de capturas de pesca
    /spots/       - Fotos de spots de pesca
    /temp/        - Uploads temporários (auto-deletados após 7 dias)

    CDN Endpoint: ${digitalocean_cdn.application_assets_cdn.endpoint}
  EOT
}
