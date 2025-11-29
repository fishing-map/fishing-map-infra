# 🔄 ArgoCD - GitOps para Kubernetes

## 🎯 O que é ArgoCD?

ArgoCD é uma ferramenta de **Continuous Delivery** declarativa para Kubernetes usando **GitOps**.

### Benefícios:
- ✅ **Deploy automático**: Git push → Deploy automático
- ✅ **Sincronização**: Git é a fonte da verdade
- ✅ **Rollback fácil**: Voltar para qualquer commit
- ✅ **UI visual**: Ver status de todos os recursos K8s
- ✅ **Multi-cluster**: Gerenciar vários clusters
- ✅ **Audit trail**: Histórico completo de mudanças

---

## 🚀 Instalação

### Via Pipeline (Automático)

A pipeline já instala o ArgoCD automaticamente:

```
Actions → DigitalOcean Kubernetes Infrastructure → Run workflow
```

### Manual (se necessário)

```bash
# Criar namespace
kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Aplicar customizações
kubectl apply -f k8s/argocd/argocd-setup.yaml

# Aguardar ficar pronto
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

---

## 🌐 Acesso

### URL
```
https://argocd.fishingmap.com.br
```

### Credenciais Iniciais

**User**: `admin`

**Password**: Obtida pela pipeline ou via:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Trocar Senha

```bash
# Via UI: User Info → Update Password

# Ou via CLI:
argocd account update-password
```

---

## 🔧 Configuração Inicial

### 1. Acessar a UI

```
https://argocd.fishingmap.com.br
Login: admin / <senha-gerada>
```

### 2. Conectar Repositório Git

**Via UI:**
```
Settings → Repositories → Connect Repo
├── Method: HTTPS
├── Type: git
├── Repository URL: https://github.com/seu-usuario/fishing-map.git
└── Username/Password ou Token
```

**Via CLI:**
```bash
argocd repo add https://github.com/seu-usuario/fishing-map.git \
  --username seu-usuario \
  --password ghp_xxxxxxxxxxxx
```

### 3. Criar Aplicação

**Via UI:**
```
Applications → New App
├── Application Name: fishing-map-backend
├── Project: default
├── Sync Policy: Automatic
├── Repository URL: https://github.com/seu-usuario/fishing-map.git
├── Revision: main
├── Path: infrastructure/k8s
├── Cluster: https://kubernetes.default.svc
└── Namespace: fishing-map
```

**Via CLI:**
```bash
argocd app create fishing-map-backend \
  --repo https://github.com/seu-usuario/fishing-map.git \
  --path infrastructure/k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace fishing-map \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

---

## 📦 Estrutura de Apps Recomendada

### Apps Criadas Automaticamente

O arquivo `argocd-setup.yaml` já cria 3 applications:

```
1. fishing-map-backend
   └── Sincroniza: infrastructure/k8s/

2. fishing-map-devtools
   └── Sincroniza: infrastructure/k8s/devtools/

3. fishing-map-observability
   └── Sincroniza: infrastructure/k8s/observability/
```

---

## 🔄 Workflow GitOps

### Como Funciona

```
1. Developer faz mudança no código
   └── git commit && git push

2. ArgoCD detecta mudança no Git
   └── Poll a cada 3 minutos (padrão)

3. ArgoCD compara Git vs Cluster
   └── Identifica diferenças

4. ArgoCD sincroniza automaticamente
   └── Aplica mudanças no cluster

5. Aplicação atualizada!
   └── Sem kubectl manual
```

### Exemplo Prático

```bash
# 1. Alterar número de replicas
# Edite: infrastructure/k8s/backend-deployment.yaml
# replicas: 2 → replicas: 3

# 2. Commit e push
git add infrastructure/k8s/backend-deployment.yaml
git commit -m "Scale backend to 3 replicas"
git push origin main

# 3. ArgoCD detecta e aplica automaticamente!
# Em ~3 minutos, terá 3 replicas rodando
```

---

## 🎛️ Funcionalidades Principais

### Sync (Sincronizar)

```bash
# Via UI: Click no botão "Sync"

# Via CLI:
argocd app sync fishing-map-backend
```

### Rollback

```bash
# Via UI: History → Rollback

# Via CLI:
argocd app rollback fishing-map-backend <revision>
```

### Refresh

```bash
# Forçar verificação do Git (sem esperar 3 min)
argocd app get fishing-map-backend --refresh
```

### Logs

```bash
# Ver logs da aplicação
argocd app logs fishing-map-backend -f
```

### Diff

```bash
# Ver diferenças entre Git e Cluster
argocd app diff fishing-map-backend
```

---

## 🔐 Segurança

### RBAC (Controle de Acesso)

**Admin** (total):
```yaml
# Já configurado no argocd-rbac-cm
User: admin
Permissions: */*/*
```

**Read-only** (visualização):
```yaml
# Para usuários que só podem ver
policy.default: role:readonly
```

### SSO (Single Sign-On)

Integre com:
- GitHub OAuth
- Google OAuth
- LDAP
- SAML

Configuração em: `argocd-cm` ConfigMap

---

## 📊 Monitoramento

### Metrics

ArgoCD expõe métricas Prometheus:

```yaml
# Já configurado no Prometheus
- job_name: 'argocd'
  static_configs:
  - targets: ['argocd-metrics:8082']
```

### Dashboards Grafana

Import dashboard ID: **14584** (ArgoCD)

```
Grafana → Import → 14584
```

### Notifications

Configure notificações no Slack/Discord:

```yaml
# argocd-notifications-cm ConfigMap
service.slack: |
  token: xoxb-your-token
template.app-deployed: |
  message: Application {{.app.metadata.name}} deployed!
```

---

## 🛠️ Troubleshooting

### App OutOfSync

```bash
# Ver diferenças
argocd app diff fishing-map-backend

# Forçar sync
argocd app sync fishing-map-backend --force
```

### Sync Falha

```bash
# Ver logs
argocd app logs fishing-map-backend --follow

# Ver eventos
kubectl get events -n fishing-map
```

### Password Perdida

```bash
# Resetar senha do admin
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

# Nova senha: password
# Troque imediatamente após login!
```

---

## 🎯 Boas Práticas

### 1. Estrutura de Repositório

```
fishing-map/
├── infrastructure/
│   └── k8s/
│       ├── base/              # Recursos base
│       ├── overlays/
│       │   ├── dev/          # Env dev
│       │   ├── staging/      # Env staging
│       │   └── production/   # Env prod
│       └── argocd/           # Apps do ArgoCD
```

### 2. Use Kustomize ou Helm

**Kustomize** (recomendado para começar):
```yaml
# kustomization.yaml
resources:
- namespace.yaml
- backend-deployment.yaml
- redis-deployment.yaml
```

**Helm** (para charts complexos):
```yaml
# values-production.yaml
replicaCount: 3
resources:
  limits:
    memory: 2Gi
```

### 3. Sync Policy

```yaml
syncPolicy:
  automated:
    prune: true        # Remove recursos deletados do Git
    selfHeal: true     # Corrige drift automático
    allowEmpty: false  # Não permite namespace vazio
```

### 4. Health Checks

ArgoCD verifica automaticamente:
- ✅ Deployments → replicas disponíveis
- ✅ Services → endpoints prontos
- ✅ Ingress → host configurado
- ✅ PVCs → bound

---

## 📱 ArgoCD CLI

### Instalação

```bash
# Linux/Mac
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Windows (via Scoop)
scoop install argocd
```

### Login

```bash
argocd login argocd.fishingmap.com.br
# Username: admin
# Password: <sua-senha>
```

### Comandos Úteis

```bash
# Listar apps
argocd app list

# Ver detalhes
argocd app get fishing-map-backend

# Sync manual
argocd app sync fishing-map-backend

# Ver logs
argocd app logs fishing-map-backend -f

# Deletar app
argocd app delete fishing-map-backend
```

---

## 🎉 Resultado Final

### Com ArgoCD Você Tem:

```
✅ Deploy automático via Git push
✅ UI visual do estado do cluster
✅ Rollback com 1 clique
✅ Histórico completo de mudanças
✅ Sincronização automática
✅ Self-healing (auto-correção)
✅ Multi-ambiente (dev/staging/prod)
✅ Audit trail completo
✅ Notificações de deploy
✅ GitOps best practices
```

### Workflow Simplificado:

```
ANTES (sem ArgoCD):
1. Editar YAML
2. kubectl apply -f ...
3. Verificar status
4. Se erro, kubectl rollback
5. Sem histórico visual

DEPOIS (com ArgoCD):
1. Editar YAML
2. git push
3. ✅ Pronto! ArgoCD faz o resto
4. UI mostra tudo visualmente
5. Rollback com 1 clique
```

---

## 📚 Recursos Adicionais

- **Documentação**: https://argo-cd.readthedocs.io/
- **GitHub**: https://github.com/argoproj/argo-cd
- **Best Practices**: https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/
- **Examples**: https://github.com/argoproj/argocd-example-apps

---

**URL**: https://argocd.fishingmap.com.br
**User**: admin
**Password**: (gerada pela pipeline)

**ArgoCD está pronto para gerenciar todo o seu cluster via GitOps!** 🚀
