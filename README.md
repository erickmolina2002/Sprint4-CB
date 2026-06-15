# wellme-back

Backend **NestJS + PostgreSQL + Docker** que serve de **insumo** para a atividade
de Cibersegurança / DevSecOps (Sprint 4) do app de bem-estar **Care Plus / WellMe**.

> ⚠️ **AVISO — código deliberadamente vulnerável para fins EDUCACIONAIS.**
> Este projeto contém 3 vulnerabilidades intencionais (marcadas com
> `// VULN INTENCIONAL`) cujo objetivo é serem **detectadas, documentadas e
> corrigidas** (entregáveis 5 e 6). **Não use em produção.**

## Stack
NestJS 11 · TypeORM (`synchronize`, sem migrações) · PostgreSQL 17 · Docker / Compose ·
Terraform (IaC) · Trivy/hadolint via container.

## As 3 vulnerabilidades (toggle por flag no `.env`)

| Flag | Vulnerabilidade | Onde | Correção (flag `false`) |
|------|-----------------|------|--------------------------|
| `VULN_V1` | Segredo do JWT vazado (hardcoded + `.env.leaked` versionado) | `src/auth/jwt.constants.ts`, `.env.leaked` | Secret só via env, sem fallback; rotacionar |
| `VULN_V2` | Dependência externa não tratada: o login chama `util.devi.tools/api/v1/notify`; quando o serviço falha (504), o app quebra com `500` (instável entre `200` e `500`) | `src/auth/auth.service.ts` | Tratar a falha (timeout/retry/circuit breaker, envio assíncrono) |
| `VULN_V3` | `GET /admin/users` sem guard, vaza todos os usuários + dados sensíveis | `src/admin/admin-access.guard.ts`, `src/admin/admin.controller.ts` | `AdminGuard` (JWT + role) + DTO sem PII |

`true` = vulnerável (gera o incidente) · `false` = corrigido (ação corretiva do entregável 6).

## Como subir

```bash
cp .env.example .env   # ajuste se quiser; o .env já vem pronto para dev
docker compose up -d db # sobe só o Postgres
npm install
npm run start:dev       # backend em http://localhost:3000
```

Ou tudo em container: `docker compose up -d --build` (app + Postgres).

## Rotas

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/health` | healthcheck |
| `GET` | `/users` | lista pública **segura** (sem dados sensíveis) — baseline |
| `POST` | `/auth/login` | `{ "name", "heroCode" }` → `{ access_token }` (V2 aqui) |
| `GET` | `/auth/me` | protegido por JWT (alvo do token forjado — V1) |
| `GET` | `/admin/users` | **V3**: sem guard quando `VULN_V3=true` |

Usuário demo: `name="Estudante FIAP"`, `heroCode="FIAP2025"`. Seed cria ~5 usuários (1 admin).

## Insumo por entregável

> O relatório consolidado (itens 4, 5 e 6) está em
> **`Trabalho_Ciberseguranca_Sprint4_WellMe.docx`** na raiz do projeto.

- **Entregável 4 (containers + IaC):** `Dockerfile` seguro, `infra/main.tf` (6 controles),
  evidências via `bash scripts/scan.sh` → `evidencias/` (Trivy, hadolint, terraform validate).
- **Entregável 5 (monitoramento):** logs JSON em `logs/app.log`
  (eventos, thresholds via grep/jq, stack Loki/Grafana opcional).
- **Entregável 6 (incidente simulado):** `bash scripts/run-incident.sh` encadeia V1→V3→V2
  e gera `evidencias/incident-output.txt`.

## Scripts
- `scripts/scan.sh` — build + Trivy + hadolint + terraform validate (evidências do item 4).
- `scripts/run-incident.sh` — executa o incidente ponta a ponta.
- `scripts/forge-token.js` — forja um JWT admin com o secret vazado (impacto de V1).
