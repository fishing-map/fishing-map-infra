# This file is replaced by cluster.tf for Kubernetes infrastructure

# Project
resource "digitalocean_project" "fishing_map" {
  name        = "${var.project_name}-${var.environment}"
  description = "FishingMap Backend Infrastructure"
  purpose     = "Web Application"
  environment = var.environment
}

# Droplet
resource "digitalocean_droplet" "fishing_map_backend" {
  image    = var.droplet_image
  name     = "${var.project_name}-${var.environment}-backend"
  region   = var.droplet_region
  size     = var.droplet_size
  backups  = var.enable_backups

  ssh_keys = [digitalocean_ssh_key.fishing_map_key.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
  })

  tags = [
    var.project_name,
    var.environment,
    "backend",
    "docker"
  ]
}

# Firewall
resource "digitalocean_firewall" "fishing_map_firewall" {
  name = "${var.project_name}-${var.environment}-firewall"

  droplet_ids = [digitalocean_droplet.fishing_map_backend.id]

  # SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTP
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Backend API (se necessário acesso direto)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "3000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound traffic (all)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Add droplet to project
resource "digitalocean_project_resources" "fishing_map_resources" {
  project = digitalocean_project.fishing_map.id
  resources = [
    digitalocean_droplet.fishing_map_backend.urn
  ]
}

# Domain (optional)
resource "digitalocean_domain" "fishing_map_domain" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

# DNS A record pointing to droplet
resource "digitalocean_record" "fishing_map_a_record" {
  count  = var.domain_name != "" ? 1 : 0
  domain = digitalocean_domain.fishing_map_domain[0].name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.fishing_map_backend.ipv4_address
  ttl    = 300
}

# DNS CNAME for www
resource "digitalocean_record" "fishing_map_cname_www" {
  count  = var.domain_name != "" ? 1 : 0
  domain = digitalocean_domain.fishing_map_domain[0].name
  type   = "CNAME"
  name   = "www"
  value  = "@"
  ttl    = 300
}

# DNS CNAME for api
resource "digitalocean_record" "fishing_map_cname_api" {
  count  = var.domain_name != "" ? 1 : 0
  domain = digitalocean_domain.fishing_map_domain[0].name
  type   = "CNAME"
  name   = "api"
  value  = "@"
  ttl    = 300
}
