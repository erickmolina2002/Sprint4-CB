#!/usr/bin/env bash
set -uo pipefail
BASE="${BASE_URL:-http://localhost:3000}"
mkdir -p evidencias
OUT="evidencias/fixed-state-output.txt"

echo "== Estado CORRIGIDO (VULN_V1=false VULN_V2=false VULN_V3=false) ==" | tee "$OUT"
date | tee -a "$OUT"

echo -e "\n[V3 corrigido] GET /admin/users SEM token deve retornar 403:" | tee -a "$OUT"
curl -s -o /dev/null -w 'sem token -> HTTP %{http_code}\n' "$BASE/admin/users" | tee -a "$OUT"

echo -e "\n[V2 corrigido] login com credencial CORRETA 6x deve ser sempre 200:" | tee -a "$OUT"
for i in $(seq 1 6); do
  code="$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/auth/login" \
    -H 'Content-Type: application/json' \
    -d '{"name":"Estudante FIAP","heroCode":"FIAP2025"}')"
  echo "login $i -> HTTP $code" | tee -a "$OUT"
done

echo -e "\n[V1 corrigido] token forjado com o secret antigo deve retornar 401:" | tee -a "$OUT"
FORGED="$(node scripts/forge-token.js)"
curl -s -o /dev/null -w 'token forjado -> HTTP %{http_code}\n' "$BASE/auth/me" -H "Authorization: Bearer $FORGED" | tee -a "$OUT"

echo -e "\n[V3 corrigido] admin REAL logado acessa /admin/users (DTO sem dados sensiveis):" | tee -a "$OUT"
TOK="$(curl -s -X POST "$BASE/auth/login" -H 'Content-Type: application/json' \
  -d '{"name":"Admin Care","heroCode":"ADMIN-9X7Q"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')"
curl -s "$BASE/admin/users" -H "Authorization: Bearer $TOK" | tee -a "$OUT"
echo "" | tee -a "$OUT"

echo "[OK] Evidencia do estado corrigido em $OUT" | tee -a "$OUT"
