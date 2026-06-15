# wellme-back

Backend **NestJS + PostgreSQL + Docker** que serve de **insumo** para a atividade
de Cibersegurança / DevSecOps (Sprint 4) do app de bem-estar **Care Plus / WellMe**.

## Stack
NestJS 11 · TypeORM (`synchronize`, sem migrações) · PostgreSQL 17 · Docker / Compose ·
Terraform (IaC) · Trivy/hadolint via container.

## As 3 vulnerabilidades (toggle por flag no `.env`)

| Flag | Vulnerabilidade | Onde | Correção (flag `false`) |
|------|-----------------|------|--------------------------|
| `VULN_V1` | Segredo do JWT vazado (hardcoded + `.env.leaked` versionado) | `src/auth/jwt.constants.ts`, `.env.leaked` | Secret só via env, sem fallback; rotacionar |
| `VULN_V2` | Dependência externa não tratada: o login chama `util.devi.tools/api/v1/notify`; quando o serviço falha (504), o app quebra com `500` (instável entre `200` e `500`) | `src/auth/auth.service.ts` | Tratar a falha (timeout/retry/circuit breaker, envio assíncrono) |
| `VULN_V3` | `GET /admin/users` sem guard, vaza todos os usuários + dados sensíveis | `src/admin/admin-access.guard.ts`, `src/admin/admin.controller.ts` | `AdminGuard` (JWT + role) + DTO sem PII |

## Como subir

Tudo em container: `docker compose up -d --build`.

## Rotas

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/health` | healthcheck |
| `GET` | `/users` | lista pública **segura** (sem dados sensíveis) - baseline |
| `POST` | `/auth/login` | `{ "name", "heroCode" }` -> `{ access_token }` (V2 aqui) |
| `GET` | `/auth/me` | protegido por JWT (alvo do token forjado - V1) |
| `GET` | `/admin/users` | **V3**: sem guard quando `VULN_V3=true` |

Usuário demo: `name="Estudante FIAP"`, `heroCode="FIAP2025"`. Seed cria ~5 usuários (1 admin).

## Scripts
- `scripts/scan.sh` - build + Trivy + hadolint + terraform validate.
- `scripts/run-incident.sh` - executa o incidente ponta a ponta.
- `scripts/forge-token.js` - forja um JWT admin com o secret vazado.
