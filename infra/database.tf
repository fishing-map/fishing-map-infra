resource "digitalocean_database_cluster" "fishing_map_db" {
  count = var.enable_managed_database ? 1 : 0

  name       = "${var.project_name}-${var.environment}-db"
  engine     = "pg"
  version    = "15"
  size       = var.database_size
  region     = var.database_region
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

# Initialize database schema and permissions
resource "null_resource" "init_database" {
  count = var.enable_managed_database ? 1 : 0

  depends_on = [
    digitalocean_database_db.fishing_map_database,
    digitalocean_database_user.fishing_map_user,
    digitalocean_database_firewall.fishing_map_db_firewall
  ]

  triggers = {
    cluster_id = digitalocean_database_cluster.fishing_map_db[0].id
    database_name = digitalocean_database_db.fishing_map_database[0].name
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Inicializando banco de dados fishing_map..."

      PGPASSWORD="${digitalocean_database_cluster.fishing_map_db[0].password}" psql \
        -h "${digitalocean_database_cluster.fishing_map_db[0].host}" \
        -p "${digitalocean_database_cluster.fishing_map_db[0].port}" \
        -U "${digitalocean_database_cluster.fishing_map_db[0].user}" \
        -d "fishing_map" \
        <<-EOSQL
          -- Criar schema public se não existir
          CREATE SCHEMA IF NOT EXISTS public;

          -- Dar permissões completas ao fishing_user no schema public
          GRANT ALL PRIVILEGES ON SCHEMA public TO fishing_user;
          GRANT ALL PRIVILEGES ON DATABASE fishing_map TO fishing_user;

          -- Permitir criar objetos no schema public
          GRANT CREATE ON SCHEMA public TO fishing_user;

          -- Permissões em tabelas e sequências futuras
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO fishing_user;
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO fishing_user;
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO fishing_user;

          -- Confirmar permissões
          SELECT 'Permissões configuradas para fishing_user' AS status;
      EOSQL

      echo "Banco inicializado com sucesso!"
    EOT
  }
}

