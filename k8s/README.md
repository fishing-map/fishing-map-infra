# Kubernetes Manifests - FishingMap (Production Ready)

Manifestos Kubernetes para produção com CI/CD totalmente automatizado via GitHub Actions.

## 🎯 Filosofia

**Zero configuração manual** - Tudo é gerenciado via:
- **Terraform**: Cria infraestrutura (DOKS + Managed PostgreSQL)
- **GitHub Actions**: Deploy automatizado dos manifestos
- **GitHub Secrets**: Credenciais sensíveis

## 📁 Estrutura

```
k8s/
├── namespace.yaml                 # Namespace
├── secrets.yaml                   # Template (preenchido pela pipeline)
├── configmap.yaml                 # Configurações (domínio fishingmap.com.br)
├── postgres-managed.yaml          # Nota sobre managed database
├── redis-deployment.yaml          # Redis cache
├── migrations-job.yaml            # Database migrations
├── backend-deployment.yaml        # Backend API
├── autoscaling.yaml               # HPA + PDB + Quotas
├── ingress-nginx.yaml             # Nginx Ingress + SSL automático
├── cert-manager-issuer.yaml       # ClusterIssuer para Let's Encrypt
├── README.md                      # Este arquivo
└── NGINX_SETUP.md                 # Guia completo do Nginx
```

## 🚀 Deploy Automatizado

### 1. Configurar GitHub Secrets

No repositório, adicione os secrets:

```
Settings > Secrets and variables > Actions > New repository secret
```

**Secrets obrigatórios:**
- `DIGITALOCEAN_TOKEN` - Token da API DigitalOcean
- `AWS_ACCESS_KEY_ID` - Para S3 backend do Terraform
- `AWS_SECRET_ACCESS_KEY` - Para S3 backend
- `JWT_SECRET` - Secret para JWT (mínimo 32 caracteres)
- `API_KEY_WEATHER` - Chave OpenWeatherMap
- `REDIS_PASSWORD` - Senha do Redis

### 2. Executar Pipeline

```
Actions > DigitalOcean Kubernetes Infrastructure > Run workflow
```

Configurar:
- **Action**: `apply`
- **Environment**: `production`
- **Enable managed database**: `true` ✅
- **Deploy K8s manifests**: `true` ✅

### 3. O que acontece automaticamente:

```
1. Terraform cria:
   ├── Cluster Kubernetes (DOKS)
   ├── PostgreSQL Managed Database
   ├── Container Registry
   └── LoadBalancer

2. Pipeline extrai outputs do Terraform:
   ├── DB_HOST
   ├── DB_PORT
   ├── DB_USER
   ├── DB_PASSWORD
   └── REGISTRY_ENDPOINT

3. Pipeline preenche secrets.yaml com:
   ├── Outputs do Terraform (database)
   └── GitHub Secrets (JWT, API keys)

4. Pipeline aplica manifestos:
   ├── Namespace
   ├── Secrets (preenchidos)
   ├── ConfigMaps
   ├── Redis
   ├── Migrations
   ├── Backend API
   └── LoadBalancer

5. Aplicação disponível em:
   └── http://<LOADBALANCER_IP>
```

## 🗄️ Managed Database

O PostgreSQL é **sempre** managed database do DigitalOcean:
- ✅ Criado via Terraform
- ✅ Backups automáticos
- ✅ Alta disponibilidade
- ✅ Firewall configurado para o cluster K8s
- ✅ Credenciais injetadas automaticamente

**Não há PostgreSQL no cluster** - apenas o Redis para cache.

## 🔐 Secrets Management

### secrets.yaml é um TEMPLATE

Os placeholders são substituídos automaticamente:

```yaml
DB_HOST: "__DB_HOST__"              # ← Terraform
DB_PORT: "__DB_PORT__"              # ← Terraform
DB_PASSWORD: "__DB_PASSWORD__"      # ← Terraform
JWT_SECRET: "__JWT_SECRET__"        # ← GitHub Secret
API_KEY_WEATHER: "__API_KEY_WEATHER__" # ← GitHub Secret
REDIS_PASSWORD: "__REDIS_PASSWORD__"   # ← GitHub Secret
```

**Nunca** edite os valores manualmente - use GitHub Secrets!

## 📊 Ordem de Deploy (Automatizada)

A pipeline segue esta ordem:

```
1. namespace.yaml          # Cria namespace
2. secrets.yaml            # Secrets preenchidos
3. configmap.yaml          # Configurações
4. redis-deployment.yaml   # Cache
5. migrations-job.yaml     # Setup do banco
6. backend-deployment.yaml # API
7. autoscaling.yaml        # Auto-scaling
8. loadbalancer-ingress.yaml # Exposição pública
```

## 🔍 Verificação Pós-Deploy

```bash
# Configurar kubectl
doctl kubernetes cluster kubeconfig save fishing-map-production-cluster

# Ver status
kubectl get all -n fishing-map

# Ver LoadBalancer IP
kubectl get svc backend-loadbalancer -n fishing-map

# Testar health check
curl http://<LOADBALANCER_IP>/health

# Ver logs
kubectl logs -l app=backend-api -n fishing-map -f
```

## 🎯 Ambientes

### Development
```yaml
# terraform.tfvars
environment = "dev"
node_pool_count = 1
enable_managed_database = false  # Opcional
```

### Staging
```yaml
# terraform.tfvars
environment = "staging"
node_pool_count = 2
enable_managed_database = true
```

### Production
```yaml
# terraform.tfvars
environment = "production"
node_pool_count = 3
enable_managed_database = true  # Obrigatório
```

## 📈 Auto-Scaling

### Pods (HPA)
- **Min**: 2 replicas
- **Max**: 10 replicas
- **Trigger**: 70% CPU ou 80% Memory

### Nodes (Cluster)
- **Min**: 1 node
- **Max**: 5 nodes (configurável)
- **Trigger**: Demanda de pods

## 🔄 Update da Aplicação

### Via GitHub Actions

1. Build nova imagem:
```bash
docker build -t registry.digitalocean.com/fishing-map/backend:v1.2.0 .
docker push registry.digitalocean.com/fishing-map/backend:v1.2.0
```

2. Atualizar tag no `backend-deployment.yaml`

3. Push para o repositório

4. Pipeline executa rolling update automaticamente

### Via kubectl (Manual)

```bash
kubectl set image deployment/backend-api \
  backend=registry.digitalocean.com/fishing-map/backend:v1.2.0 \
  -n fishing-map

kubectl rollout status deployment/backend-api -n fishing-map
```

## 🛡️ Segurança

- ✅ **Secrets em base64** no cluster
- ✅ **GitHub Secrets** para dados sensíveis
- ✅ **Terraform state** criptografado no S3
- ✅ **Container Registry** privado
- ✅ **Database firewall** limitado ao cluster K8s
- ✅ **Resource limits** em todos os pods
- ✅ **PodDisruptionBudget** para alta disponibilidade

## 💰 Custos Estimados (Production)

```
Cluster DOKS (3 nodes s-2vcpu-4gb):  $72/mês
Managed PostgreSQL (db-s-2vcpu-4gb): $60/mês
Container Registry (basic):           $5/mês
LoadBalancer:                        $12/mês
──────────────────────────────────────────────
Total:                              ~$149/mês
```

## 🚨 Troubleshooting

### Pipeline falha no Terraform
- Verificar GitHub Secrets configurados
- Verificar quota do DigitalOcean
- Ver logs da Action

### Migrations falham
```bash
kubectl logs -l app=migrations -n fishing-map
kubectl describe job db-migrations -n fishing-map
```

### Backend não inicia
```bash
kubectl describe pod <pod-name> -n fishing-map
kubectl logs <pod-name> -n fishing-map
```

### Sem LoadBalancer IP
```bash
# Aguardar 2-5 minutos
kubectl get svc backend-loadbalancer -n fishing-map -w
```

## 📚 Documentação Adicional

- [DigitalOcean Kubernetes](https://docs.digitalocean.com/products/kubernetes/)
- [Managed Databases](https://docs.digitalocean.com/products/databases/)
- [Container Registry](https://docs.digitalocean.com/products/container-registry/)

---

## ✅ Checklist de Produção

- [ ] GitHub Secrets configurados
- [ ] Terraform backend S3 criado
- [ ] Imagens Docker publicadas no registry
- [ ] Pipeline executada com sucesso
- [ ] LoadBalancer com IP público
- [ ] Health check respondendo
- [ ] Logs sendo gerados
- [ ] Monitoring configurado
- [ ] SSL/domínio configurado (opcional)
- [ ] Backups do banco testados

---

**🎉 Infraestrutura Production-Ready com CI/CD 100% Automatizado!**
