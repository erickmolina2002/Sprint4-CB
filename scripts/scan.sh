#!/usr/bin/env bash
set -uo pipefail
mkdir -p evidencias

echo "== [1/7] docker build =="
docker build -t wellme-back:secure . 2>&1 | tee evidencias/build-log.txt

echo "== [2/7] usuario e tamanho da imagem =="
docker image inspect wellme-back:secure --format 'USER={{.Config.User}}' | tee evidencias/image-user.txt
docker images wellme-back:secure --format 'IMAGE={{.Repository}}:{{.Tag}}  SIZE={{.Size}}' | tee evidencias/image-size.txt
docker image inspect wellme-back:secure --format 'CONTENT_SIZE_BYTES={{.Size}}' | tee -a evidencias/image-size.txt

echo "== [3/7] hadolint - lint do Dockerfile (saida bruta) =="
docker pull -q hadolint/hadolint >/dev/null 2>&1 || true
docker run --rm -i hadolint/hadolint < Dockerfile > evidencias/hadolint-report.txt 2>&1
HEC=$?
echo "hadolint exit code: $HEC (0 = sem apontamentos)" >> evidencias/hadolint-report.txt
cat evidencias/hadolint-report.txt

echo "== [4/7] Trivy - scan da IMAGEM (CVEs por severidade) =="
docker save wellme-back:secure -o evidencias/_image.tar
docker run --rm -v wellme_trivy_cache:/root/.cache/trivy -v "$(pwd)/evidencias":/work -w /work aquasec/trivy:latest image --input _image.tar 2>&1 | tee evidencias/trivy-image-report.txt || true
rm -f evidencias/_image.tar

echo "== [5/7] Trivy - scan de FILESYSTEM/deps + segredos =="
docker run --rm -v wellme_trivy_cache:/root/.cache/trivy -v "$(pwd)":/src -w /src aquasec/trivy:latest fs --scanners vuln,secret . 2>&1 | tee evidencias/trivy-fs-report.txt || true

echo "== [6/7] Terraform fmt + validate (IaC) =="
docker run --rm -v "$(pwd)/infra":/work -w /work hashicorp/terraform:latest init -backend=false 2>&1 | tee evidencias/terraform-init.txt || true
docker run --rm -v "$(pwd)/infra":/work -w /work hashicorp/terraform:latest validate 2>&1 | tee evidencias/terraform-validate.txt || true

echo "== [7/7] Evidencia do segredo vazado (V1) =="
{
  echo "# Segredo de assinatura do JWT exposto em .env.leaked (commitado por engano):"
  grep -nE 'JWT_SECRET|PASSWORD' .env.leaked
  if git rev-parse --git-dir >/dev/null 2>&1; then
    echo "# Historico git do arquivo vazado:"
    git log --oneline -- .env.leaked 2>/dev/null
  else
    echo "# (sem repositorio git ainda - rode 'git init && git add . && git commit' para evidenciar via historico)"
  fi
} | tee evidencias/leaked-secret.txt

echo "[OK] Evidencias geradas em evidencias/"
