# 🔑 GUIA COMPLETO - ONDE GERAR CADA CREDENCIAL

## 📋 CREDENCIAIS NECESSÁRIAS (4)

Você precisa de **4 secrets** no GitHub. Vou te mostrar EXATAMENTE onde gerar cada uma.

---

## 1️⃣ DIGITALOCEAN_TOKEN

### O que é:
Personal Access Token da DigitalOcean (para gerenciar recursos)

### Onde gerar:
```
1. Acesse: https://cloud.digitalocean.com/account/api/tokens

2. Clique na aba "Personal Access Tokens"

3. Clique em "Generate New Token"

4. Configuração:
   └── Name: terraform-fishing-map
   └── Scopes: Read & Write (marcar tudo)
   └── Expiration: No expiry (ou 90 days)

5. Clique em "Generate Token"

6. ⚠️ COPIE O TOKEN IMEDIATAMENTE!
   └── Começa com: dop_v1_...
   └── Exemplo: dop_v1_abc123def456ghi789...

7. Cole no GitHub:
   Repository → Settings → Secrets → Actions
   Nome: DIGITALOCEAN_TOKEN
   Valor: dop_v1_abc123def456ghi789...
```

**URL Direta**: https://cloud.digitalocean.com/account/api/tokens

---

## 2️⃣ SPACES_ACCESS_KEY + SPACES_SECRET_KEY

### O que são:
Par de chaves para acessar DigitalOcean Spaces (object storage)

### Onde gerar:
```
1. Acesse: https://cloud.digitalocean.com/account/api/spaces

2. Clique na aba "Access Keys"

3. Clique em "Create Access Key"

4. Configuração:
   └── Name: fishing-map-spaces

5. Clique em "Create Access Key"

6. ⚠️ UMA JANELA APARECERÁ COM 2 VALORES!
   
   Access Key ID:     DO00WRDPEKTPHMJGB43C
   Secret Access Key: 0yZE2jRMW5HMdHvzxEfBITSxHKLhkaHugbblH9CnS3E
   
   ⚠️ COPIE AMBOS IMEDIATAMENTE!
   (A Secret Key só aparece uma vez!)

7. Cole no GitHub como 2 SECRETS SEPARADOS:

   Secret 1:
   Nome: SPACES_ACCESS_KEY
   Valor: DO00WRDPEKTPHMJGB43C
   
   Secret 2:
   Nome: SPACES_SECRET_KEY
   Valor: 0yZE2jRMW5HMdHvzxEfBITSxHKLhkaHugbblH9CnS3E
```

**URL Direta**: https://cloud.digitalocean.com/account/api/spaces

---

## 3️⃣ REDIS_PASSWORD

### O que é:
Senha para o Redis no cluster Kubernetes

### Onde gerar:
```
1. Gere localmente no terminal:

   # Via OpenSSL (mais seguro)
   openssl rand -base64 32

   # Ou via Node.js
   node -e "console.log(require('crypto').randomBytes(24).toString('base64'))"

2. ⚠️ COPIE O RESULTADO!
   Exemplo: L5mX9pQ2vR8wL4nY7tB6jH3dF1sA0cZ9xE5mW4v

3. Cole no GitHub:
   Repository → Settings → Secrets → Actions
   Nome: REDIS_PASSWORD
   Valor: L5mX9pQ2vR8wL4nY7tB6jH3dF1sA0cZ9xE5mW4v
```

**Comando rápido**:
```bash
openssl rand -base64 32
```

---

## 4️⃣ DOMAIN_NAME (Opcional)

### O que é:
Nome do domínio (variable, não secret)

### Onde configurar:
```
1. Acesse: Repository → Settings → Secrets and variables → Actions

2. Clique na aba "Variables"

3. Clique em "New repository variable"

4. Configuração:
   Nome: DOMAIN_NAME
   Valor: fishingmap.com.br

5. Clique em "Add variable"
```

---

## ✅ RESUMO RÁPIDO

### DigitalOcean (2 lugares):

**Personal Access Tokens:**
- https://cloud.digitalocean.com/account/api/tokens
- Gera: `DIGITALOCEAN_TOKEN`

**Spaces Access Keys:**
- https://cloud.digitalocean.com/account/api/spaces
- Gera: `SPACES_ACCESS_KEY` + `SPACES_SECRET_KEY` (1 ação, 2 valores)

### Local (Terminal):

```bash
openssl rand -base64 32
```
- Gera: `REDIS_PASSWORD`

---

## 📝 CHECKLIST DE CONFIGURAÇÃO

### No DigitalOcean:

- [ ] Gerei Personal Access Token (dop_v1_...)
- [ ] Gerei Spaces Access Key (DO00...)
- [ ] Copiei Spaces Secret Key (texto longo)

### No Terminal:

- [ ] Gerei Redis Password (openssl rand -base64 32)

### No GitHub:

- [ ] Adicionei DIGITALOCEAN_TOKEN (Secret)
- [ ] Adicionei SPACES_ACCESS_KEY (Secret)
- [ ] Adicionei SPACES_SECRET_KEY (Secret)
- [ ] Adicionei REDIS_PASSWORD (Secret)
- [ ] Adicionei DOMAIN_NAME (Variable - opcional)

---

## 🎯 PRÓXIMO PASSO

Após configurar todas as 4 credenciais:

1. **Execute o bootstrap** (já fez ✅)
   ```bash
   cd infrastructure/bootstrap
   terraform apply
   ```

2. **Execute a pipeline**
   ```
   GitHub Actions → Run workflow → Apply
   ```

3. **Pronto!** Infraestrutura será criada! 🚀

---

## 💡 DICAS

### Personal Access Token vs Spaces Keys:
```
Personal Access Token (dop_v1_...)
└── Gerencia TODOS os recursos (cluster, database, etc)

Spaces Access Keys (DO00...)
└── Acessa APENAS Spaces (object storage)

São DIFERENTES! Você precisa de AMBOS!
```

### Segurança:
```
✅ Nunca compartilhe estas credenciais
✅ Use expiration no Personal Token se possível
✅ Troque periodicamente (a cada 3-6 meses)
✅ Revogue tokens antigos não utilizados
```

---

## 🆘 TROUBLESHOOTING

### "InvalidAccessKeyId" na pipeline:
```
Causa: SPACES_ACCESS_KEY ou SPACES_SECRET_KEY incorretos
Solução: Gere novamente em /account/api/spaces e atualize no GitHub
```

### "Missing DIGITALOCEAN_TOKEN":
```
Causa: Token não configurado no GitHub
Solução: Gere em /account/api/tokens e adicione como secret
```

### "Forbidden 403":
```
Causa: Token sem permissões ou revogado
Solução: Gere novo token com Read & Write em TODAS as scopes
```

---

**URLs Importantes:**

- Personal Tokens: https://cloud.digitalocean.com/account/api/tokens
- Spaces Keys: https://cloud.digitalocean.com/account/api/spaces
- GitHub Secrets: https://github.com/fishing-map/fishing-map-infra/settings/secrets/actions

**Pronto para configurar!** 🔑
