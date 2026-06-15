# IaC - Infraestrutura como Código (entregável 4)

Arquivo `main.tf` que declara o deploy do container `wellme-back` com **6 controles
de segurança** explícitos. Escrito em Terraform (HCL) por ser declarativo e deixar
os controles legíveis para o relatório.

## Controles de segurança aplicados

| # | Controle | Onde no `main.tf` |
|---|----------|-------------------|
| C1 | `no-new-privileges` (sem escalonamento de privilégio) | `security_opts` |
| C2 | Root filesystem **somente-leitura** + `tmpfs` para diretórios graváveis | `read_only` + `mounts` |
| C3 | **Drop ALL** capabilities do kernel (menor privilégio) | `capabilities { drop }` |
| C4 | Limites de **memória e CPU** (mitiga DoS/abuso) | `memory`, `cpu_shares` |
| C5 | Segredo via variável `sensitive` (nunca hardcoded/versionado) | `var.jwt_secret` |
| C6 | **Rede isolada** + expõe apenas a porta da aplicação | `docker_network` + `ports` |

## Validação (gera evidência - via Docker, sem instalar Terraform no host)

```bash
# a partir da raiz do projeto:
docker run --rm -v "$(pwd)/infra":/work -w /work hashicorp/terraform:latest fmt -check
docker run --rm -v "$(pwd)/infra":/work -w /work hashicorp/terraform:latest init -backend=false
docker run --rm -v "$(pwd)/infra":/work -w /work hashicorp/terraform:latest validate
```