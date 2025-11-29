# 🚀 Bootstrap - Criar Bucket de Terraform State

## 📋 O QUE É ISSO?

Este projeto cria **apenas o bucket Spaces** que será usado como backend do Terraform.

Execute **UMA VEZ** na sua máquina local **ANTES** de executar a pipeline principal.

---

## 🔧 PASSO A PASSO

### 1. Configure as variáveis

```bash
cd infrastructure/bootstrap
cp terraform.tfvars terraform.tfvars
```

Edite `terraform.tfvars` com seus valores:
```hcl
do_token       = "dop_v1_seu_token_aqui"
bucket_name    = "fishing-map-prod-terraform-state"
spaces_region  = "nyc3"
```

### 2. Inicialize o Terraform

```bash
terraform init
```

### 3. Verifique o plano

```bash
terraform plan
```

Deve mostrar:
```
Plan: 1 to add, 0 to change, 0 to destroy.

+ digitalocean_spaces_bucket.terraform_state
```

### 4. Crie o bucket

```bash
terraform apply
```

Digite `yes` quando solicitado.

### 5. Veja o output

Após sucesso, você verá:
```
bucket_name = "fishing-map-prod-terraform-state"
bucket_endpoint = "https://fishing-map-prod-terraform-state.nyc3.digitaloceanspaces.com"
spaces_endpoint = "https://nyc3.digitaloceanspaces.com"

next_steps = <<EOT
✅ Bucket criado com sucesso!
...
EOT
```

---

## ✅ PRONTO!

Agora o bucket existe e você pode:

1. **Descomente o backend no `infra/main.tf`**
2. **Execute a pipeline principal**
3. O Terraform vai encontrar o bucket e usar como backend!

---

## 🔄 DESCOMENTE O BACKEND

No arquivo `infrastructure/infra/main.tf`, descomente:

```terraform
backend "s3" {
  endpoint                    = "https://nyc3.digitaloceanspaces.com"
  bucket                      = "fishing-map-prod-terraform-state"
  key                         = "terraform.tfstate"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
```

E atualize a pipeline para incluir a configuração do backend.

---

## 🗑️ Deletar (SE NECESSÁRIO)

Se precisar deletar o bucket:

```bash
terraform destroy
```

**⚠️ CUIDADO:** Isso vai deletar o bucket e você perderá o state se já tiver migrado!

---

## 💡 POR QUE FAZER ASSIM?

### Problema do "Ovo e Galinha":
- Terraform precisa do bucket para guardar state
- Mas o bucket é criado pelo Terraform
- Solução: Criar o bucket separadamente primeiro!

### Benefícios:
```
✅ Bucket existe antes da pipeline rodar
✅ Pipeline principal usa backend remoto desde o início
✅ Não precisa migrar state depois
✅ Simples e direto
```

---

## 📝 ARQUIVOS

```
bootstrap/
├── main.tf                     # Cria o bucket
├── variables.tf                # Variáveis
├── terraform.tfvars.example    # Template
└── README.md                   # Este arquivo
```

---

## 🎯 RESUMO

```bash
# 1. Configure
cd infrastructure/bootstrap
cp terraform.tfvars terraform.tfvars
vim terraform.tfvars

# 2. Crie o bucket
terraform init
terraform apply

# 3. Descomente backend no main.tf

# 4. Execute a pipeline principal
# ✅ Pronto!
```

---

**Execute isso UMA VEZ na sua máquina e nunca mais precisa se preocupar!** 🚀
