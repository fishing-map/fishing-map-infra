# FishingMap Infrastructure - DigitalOcean Kubernetes (DOKS)

Infraestrutura como código (IaC) para o FishingMap utilizando DigitalOcean Kubernetes Service (DOKS) com CI/CD totalmente automatizado.

## 🎯 Arquitetura Implementada

### Stack Completa
- **Cluster Kubernetes (DOKS)**: Auto-scaling de 1-5 nodes
- **PostgreSQL Managed**: Banco com PostGIS (geoespacial)
- **Redis**: Cache em cluster
- **DigitalOcean Spaces**: Object storage (fotos + terraform state)
- **Nginx Ingress**: Proxy reverso com SSL automático
- **cert-manager**: Certificados Let's Encrypt automáticos
- **Container Registry**: Registry privado DigitalOcean

### Serviços Adicionais
- **ArgoCD**: GitOps e Continuous Delivery
- **SonarQube**: Análise de qualidade de código
- **Observability Stack**: Prometheus, Grafana, Loki, Jaeger
- **Kafka + Zookeeper**: Mensageria e event streaming

### Domínios Configurados
```
https://api.fishingmap.com.br          → Backend API
https://fishingmap.com.br              → Landing page (futuro)
https://app.fishingmap.com.br          → Web app (futuro)
https://argocd.fishingmap.com.br       → GitOps / Continuous Delivery
https://sonarqube.fishingmap.com.br    → Code quality
https://grafana.fishingmap.com.br      → Monitoring
https://jaeger.fishingmap.com.br       → Tracing
```

---

## 📋 Pré-requisitos

### 1. Conta DigitalOcean
- Token da API: https://cloud.digitalocean.com/account/api/tokens
- Spaces Access Keys: https://cloud.digitalocean.com/account/api/spaces

### 2. Domínio Registrado
- `fishingmap.com.br` no Registro.br

### 3. GitHub Secrets Configurados

Acesse: `Settings > Secrets and variables > Actions > New repository secret`

#### Secrets Obrigatórios:

```bash
# DigitalOcean
DIGITALOCEAN_TOKEN=dop_v1_xxxxxxxxxxxxx

# Spaces (Object Storage)
SPACES_ACCESS_KEY=DO00ABC123XYZ
SPACES_SECRET_KEY=abc123def456ghi789...

# Database (se não usar managed, mas recomendado usar managed)
# Estas serão preenchidas automaticamente pelo Terraform se usar managed database

# JWT & Refresh Tokens
JWT_SECRET=<64+ caracteres aleatórios>
REFRESH_TOKEN_SECRET=<64+ caracteres aleatórios - diferente do JWT_SECRET>

# Redis
REDIS_PASSWORD=<senha forte>

# External APIs
API_KEY_WEATHER=<chave OpenWeatherMap - grátis em https://openweathermap.org/api>
```

#### Secrets Opcionais (para funcionalidades específicas):

```bash
# AWS S3 (se for usar S3 além dos Spaces - não necessário por padrão)
AWS_ACCESS_KEY_ID=<se usar S3>
AWS_SECRET_ACCESS_KEY=<se usar S3>

# SendGrid/Email (se tiver notificações por email)
SENDGRID_API_KEY=<se usar>

# Firebase/Push Notifications (para notificações push no app)
FIREBASE_SERVER_KEY=<se usar>
```

### 4. GitHub Variables Configurados

Acesse: `Settings > Secrets and variables > Actions > Variables > New repository variable`

```bash
TF_BACKEND_BUCKET=fishing-map-dev-terraform-state
DOMAIN_NAME=fishingmap.com.br
```

---

## 🚀 Deploy Completo via GitHub Actions

### Passo 1: Executar Pipeline

1. Acesse `Actions > DigitalOcean Kubernetes Infrastructure`
2. Clique em `Run workflow`
3. Configure:
   - **Action**: `apply`
   - **Environment**: `production`
   - **Enable managed database**: `true`
   - **Deploy K8s manifests**: `true`

### Passo 2: Aguardar Deploy

A pipeline executará automaticamente:

```
1. Terraform cria infraestrutura (~10 min)
   ├── Cluster Kubernetes (DOKS)
   ├── PostgreSQL Managed
   ├── Container Registry
   ├── 2 Buckets Spaces (terraform state + assets)
   └── CDN para assets

2. Instala Nginx Ingress Controller (~2 min)
   └── LoadBalancer DigitalOcean

3. Instala cert-manager (~2 min)
   └── Preparação para SSL automático

4. Extrai outputs do Terraform
   └── Database credentials, endpoints, etc

5. Preenche secrets do Kubernetes (~1 min)
   ├── Database (do Terraform)
   ├── JWT, Redis, API keys (do GitHub)
   └── Spaces credentials

6. Deploy da aplicação (~5 min)
   ├── Redis
   ├── Migrations (projeto separado)
   ├── Backend API
   └── Auto-scaling configurado

7. Configura Ingress + SSL (~3 min)
   ├── ClusterIssuer (Let's Encrypt)
   ├── Ingress Nginx
   └── Certificados (emitidos após DNS)

Total: ~15-20 minutos
```

### Passo 3: Obter IP do LoadBalancer

A pipeline mostrará:
```
🌐 Nginx LoadBalancer IP: 203.0.113.45
```

Ou obtenha manualmente:
```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Passo 4: Configurar DNS

No painel do Registro.br (https://registro.br/), configure **7 registros A**:

```
TIPO    NOME           VALOR (IP do LoadBalancer)
──────────────────────────────────────────────────
A       @              203.0.113.45
A       www            203.0.113.45
A       api            203.0.113.45
A       app            203.0.113.45
A       sonarqube      203.0.113.45
A       grafana        203.0.113.45
A       jaeger         203.0.113.45
```

**Guias detalhados**:
- `DNS_SETUP_GUIDE.md` - Completo com troubleshooting
- `DNS_QUICK_CONFIG.md` - Rápido, copiar e colar

### Passo 5: Aguardar Propagação

- **DNS**: 15-30 minutos
- **Certificados SSL**: 5-15 minutos após DNS

Verificar:
```bash
nslookup api.fishingmap.com.br
kubectl get certificate -n fishing-map
```

### Passo 6: Acessar Aplicação

```bash
# Backend API
curl https://api.fishingmap.com.br/health

# SonarQube
https://sonarqube.fishingmap.com.br
Login: admin / admin (trocar no primeiro acesso)

# Grafana
https://grafana.fishingmap.com.br
Login: admin / admin

# Jaeger
https://jaeger.fishingmap.com.br
```

---

## 📁 Estrutura de Arquivos

```
infrastructure/
├── infra/                           # Terraform
│   ├── main.tf                      # Provider e backend
│   ├── variables.tf                 # Variáveis
│   ├── cluster.tf                   # DOKS cluster
│   ├── database.tf                  # PostgreSQL managed
│   ├── spaces.tf                    # Object storage (2 buckets)
│   ├── outputs.tf                   # Outputs
│   └── terraform.tfvars.example     # Template de variáveis
│
├── k8s/                             # Kubernetes Manifests
│   ├── namespace.yaml               # Namespace
│   ├── secrets.yaml                 # Secrets (template)
│   ├── configmap.yaml               # Configs
│   ├── redis-deployment.yaml        # Cache
│   ├── migrations-job.yaml          # DB migrations
│   ├── backend-deployment.yaml      # Backend API
│   ├── autoscaling.yaml             # HPA + PDB
│   ├── ingress-nginx.yaml           # Ingress + SSL
│   ├── cert-manager-issuer.yaml     # SSL issuer
│   │
│   ├── devtools/                    # Ferramentas de desenvolvimento
│   │   ├── sonarqube.yaml           # SonarQube + PostgreSQL
│   │   └── ingress.yaml             # Ingress para devtools
│   │
│   ├── observability/               # Monitoramento
│   │   ├── stack.yaml               # Prometheus, Grafana, Loki, Jaeger
│   │   └── configmaps.yaml          # Configurações
│   │
│   └── messaging/                   # Mensageria
│       └── kafka.yaml               # Kafka + Zookeeper
│
├── .github/workflows/
│   └── infra-digitalocean.yml       # Pipeline CI/CD
│
└── Documentação
    ├── README.md                    # Este arquivo
    ├── PRODUCTION_READY.md          # Guia completo CI/CD
    ├── SPACES_COMPLETE.md           # Object storage
    ├── NGINX_COMPLETE.md            # Proxy reverso + SSL
    ├── ENV_VARIABLES_COMPLETE.md    # Todas as variáveis
    ├── DNS_SETUP_GUIDE.md           # Configuração DNS detalhada
    ├── DNS_QUICK_CONFIG.md          # DNS rápido
    └── ADDITIONAL_SERVICES.md       # SonarQube, Observability, Kafka
```

---

## 🔧 Configuração Manual (Terraform CLI)

Se preferir rodar Terraform localmente:

### 1. Preparar Ambiente

```bash
cd infrastructure/infra
cp terraform.tfvars.example terraform.tfvars
```

### 2. Editar terraform.tfvars

```hcl
do_token             = "dop_v1_xxxxxxxxxxxxx"
project_name         = "fishing-map"
environment          = "production"
cluster_region       = "nyc3"
node_pool_size       = "s-2vcpu-4gb"
node_pool_count      = 3
enable_managed_database = true
database_size        = "db-s-2vcpu-4gb"
spaces_region        = "nyc3"
```

### 3. Inicializar Terraform

```bash
terraform init
```

### 4. Executar

```bash
# Ver plano
terraform plan

# Aplicar
terraform apply

# Ver outputs
terraform output
```

---

## 📦 Serviços Opcionais (Deploy Seletivo)

Você pode escolher quais serviços adicionais deployar:

### Deploy Apenas SonarQube

```bash
kubectl apply -f k8s/devtools/
```

### Deploy Apenas Observability

```bash
kubectl apply -f k8s/observability/
```

### Deploy Apenas Kafka

```bash
kubectl apply -f k8s/messaging/
```

### Deploy Tudo

```bash
kubectl apply -f k8s/ --recursive
```

---

## 💰 Custos Estimados

### Infraestrutura Base (Obrigatória)

```
DOKS Cluster (3 nodes s-2vcpu-4gb):  $72/mês
PostgreSQL Managed (db-s-2vcpu-4gb): $60/mês
Container Registry (basic):          $5/mês
Nginx LoadBalancer:                  $12/mês
Spaces (2 buckets + CDN):            $5/mês
──────────────────────────────────────────────
Subtotal:                           $154/mês
```

### Serviços Opcionais

```
SonarQube + Observability + Kafka:
├── Storage (PVCs): ~47Gi × $0.10 = $4.70/mês
├── Compute: +1 node necessário    = $24/mês
──────────────────────────────────────────────
Subtotal Opcional:                  $30/mês
```

### **TOTAL: $154-184/mês (~R$ 770-920/mês)**

**vs AWS equivalente**: $400-500/mês
**Economia**: 55-65% 💰

---

## 🔍 Monitoramento e Manutenção

### Verificar Status do Cluster

```bash
# Configurar kubectl
doctl kubernetes cluster kubeconfig save fishing-map-production-cluster

# Ver nodes
kubectl get nodes

# Ver todos os pods
kubectl get pods -n fishing-map

# Ver serviços
kubectl get svc -n fishing-map

# Ver ingress
kubectl get ingress -n fishing-map
```

### Logs

```bash
# Backend API
kubectl logs -l app=backend-api -n fishing-map -f

# Redis
kubectl logs -l app=redis -n fishing-map

# Migrations
kubectl logs -l app=migrations -n fishing-map

# Nginx Ingress
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f
```

### Métricas (via Grafana)

Acesse: https://grafana.fishingmap.com.br

Dashboards disponíveis:
- Kubernetes cluster metrics
- Backend API performance
- Database connections
- Request rate e latency
- Error rates

### Scaling Manual

```bash
# Escalar backend API
kubectl scale deployment backend-api --replicas=5 -n fishing-map

# Escalar cluster nodes (via Terraform)
# Edite: node_pool_count = 5
terraform apply
```

---

## 🔐 Segurança

### Medidas Implementadas

- ✅ **Network Policies**: Isolamento de pods
- ✅ **RBAC**: Controle de acesso granular
- ✅ **Secrets Management**: Credenciais criptografadas
- ✅ **SSL/TLS**: Todos os domínios com HTTPS
- ✅ **Rate Limiting**: 100 req/s por IP
- ✅ **Security Headers**: X-Frame-Options, CSP, etc
- ✅ **Resource Limits**: Todos os pods com limits
- ✅ **PodDisruptionBudget**: Alta disponibilidade
- ✅ **Database Firewall**: Apenas cluster K8s acessa
- ✅ **Private Registry**: Container images privadas

### Recomendações Adicionais

- [ ] Configurar WAF (Cloudflare)
- [ ] Implementar Falco para runtime security
- [ ] Configurar OPA para policy enforcement
- [ ] Habilitar audit logs
- [ ] Configurar backup automático de Spaces
- [ ] Implementar disaster recovery plan

---

## 🆘 Troubleshooting

### Pipeline Falha

```bash
# Ver logs da Action no GitHub
Actions → Run → Ver output

# Erros comuns:
# 1. Secrets não configurados → Verificar GitHub Secrets
# 2. Quota excedida → Aumentar quota no DigitalOcean
# 3. Token inválido → Gerar novo token
```

### Pods Não Iniciam

```bash
# Descrever pod
kubectl describe pod <pod-name> -n fishing-map

# Ver eventos
kubectl get events -n fishing-map --sort-by='.lastTimestamp'

# Erros comuns:
# 1. ImagePullBackOff → Verificar registry credentials
# 2. CrashLoopBackOff → Ver logs do pod
# 3. Pending → Verificar resources/PVCs
```

### Certificado SSL Não Emitido

```bash
# Ver certificados
kubectl get certificate -n fishing-map

# Ver challenges
kubectl get challenges -n fishing-map

# Ver logs cert-manager
kubectl logs -n cert-manager deployment/cert-manager

# Causa comum: DNS não propagou ou apontando errado
nslookup api.fishingmap.com.br
```

### Backend API Retorna 502

```bash
# Verificar se pods estão rodando
kubectl get pods -l app=backend-api -n fishing-map

# Ver logs
kubectl logs -l app=backend-api -n fishing-map

# Verificar health check
kubectl describe pod <backend-pod> -n fishing-map
```

### Database Connection Error

```bash
# Verificar managed database
doctl databases list

# Ver connection info
kubectl get secret fishing-map-secrets -n fishing-map -o yaml

# Testar conexão do pod
kubectl exec -it <backend-pod> -n fishing-map -- sh
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

---

## 🔄 Atualização da Aplicação

### Via CI/CD (Recomendado)

1. **Push para branch main**
2. **Build da imagem Docker** (GitHub Actions separada)
3. **Push para DigitalOcean Registry**
4. **Rolling update automático** no Kubernetes

### Manual

```bash
# Build e push da imagem
docker build -t registry.digitalocean.com/fishing-map/backend:v1.2.0 .
docker push registry.digitalocean.com/fishing-map/backend:v1.2.0

# Update deployment
kubectl set image deployment/backend-api \
  backend=registry.digitalocean.com/fishing-map/backend:v1.2.0 \
  -n fishing-map

# Verificar rollout
kubectl rollout status deployment/backend-api -n fishing-map
```

---

## 📊 Backup e Disaster Recovery

### Backups Automáticos

- **PostgreSQL Managed**: Backups diários automáticos (retidos 7 dias)
- **Spaces**: Versionamento habilitado
- **Terraform State**: Versionado no Spaces

### Backup Manual

```bash
# Backup do banco
kubectl exec -it <postgres-pod> -n fishing-map -- \
  pg_dump -U postgres fishing_map > backup.sql

# Upload para Spaces
s3cmd put backup.sql s3://fishing-map-production-assets/backups/
```

### Disaster Recovery

1. **Criar novo cluster**: Execute pipeline novamente
2. **Restaurar database**: Use backup mais recente
3. **Reconfigurar DNS**: Apontar para novo IP
4. **Testar aplicação**: Verificar funcionamento

---

## 📚 Documentação Adicional

- **PRODUCTION_READY.md** - Guia completo de CI/CD automatizado
- **SPACES_COMPLETE.md** - Object storage e CDN
- **NGINX_COMPLETE.md** - Proxy reverso e SSL
- **ENV_VARIABLES_COMPLETE.md** - Todas as variáveis necessárias
- **DNS_SETUP_GUIDE.md** - Configuração DNS detalhada
- **ADDITIONAL_SERVICES.md** - SonarQube, Observability, Kafka
- **MIGRATION_COMPLETE_DOKS.md** - Histórico da migração

---

## 🎉 Resultado Final

### Stack Completa Deployada

```
✅ Cluster Kubernetes auto-scaling
✅ PostgreSQL Managed com PostGIS
✅ Redis para cache
✅ Object Storage (Spaces) + CDN
✅ Nginx Ingress + SSL automático
✅ Backend API com HPA
✅ Migrations em projeto separado
✅ Container Registry privado
✅ SonarQube para code quality
✅ Observability stack completa
✅ Kafka para mensageria
✅ 6 domínios com HTTPS
✅ CI/CD totalmente automatizado
```

### Pronto para Produção

- 🚀 **Deploy em 1 clique** via GitHub Actions
- 🔐 **Segurança**: SSL, RBAC, Network Policies
- 📊 **Monitoramento**: Prometheus, Grafana, Loki, Jaeger
- 🔄 **Auto-scaling**: Pods e Nodes
- 💰 **Custo otimizado**: 55-65% mais barato que AWS
- 🌍 **Global**: CDN para assets
- 🛡️ **Alta disponibilidade**: Multi-node cluster
- 📈 **Escalável**: Preparado para microserviços

---

## 📞 Suporte

Para problemas ou dúvidas:

1. **Verificar logs** da pipeline no GitHub Actions
2. **Consultar documentação** específica em `/infrastructure/*.md`
3. **Verificar troubleshooting** neste README
4. **Abrir issue** no repositório

---

**Desenvolvido com ❤️ para FishingMap**

**Stack**: DigitalOcean Kubernetes, NestJS, PostgreSQL, Redis, React Native

**Custo**: $154-184/mês | **Economia**: 55-65% vs AWS | **Production-Ready**: ✅
