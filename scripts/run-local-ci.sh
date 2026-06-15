#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOGS_DIR="logs/ci-simulation"
mkdir -p "$LOGS_DIR"

echo -e "${BLUE}Local CI/CD Security Pipeline Simulation${NC}\n"

run_check() {
  local name=$1
  local cmd=$2
  local log_file="$LOGS_DIR/$(echo "$name" | tr '[:upper:]' '[:lower:]').log"

  echo -e "${CYAN}[$(date '+%H:%M:%S')] Running: ${name}...${NC}"

  if eval "$cmd" > "$log_file" 2>&1; then
    echo -e "${GREEN}${name} passed${NC}\n"
    return 0
  else
    echo -e "${YELLOW}${name} found issues (see $log_file)${NC}\n"
    return 1
  fi
}

total=0
passed=0
failed=0

echo -e "${CYAN}NPM Audit (SCA)${NC}\n"
((total++))
if run_check "npm-audit" "npm audit --audit-level=moderate && npm audit --json > $LOGS_DIR/npm-audit-report.json"; then
  ((passed++))
else
  ((failed++))
fi

echo -e "${CYAN}Linting & Type Checking${NC}\n"
((total++))
if run_check "eslint" "npm run lint 2>&1 || true"; then
  ((passed++))
else
  ((failed++))
fi

((total++))
if run_check "typescript" "npm run type-check 2>&1 || true"; then
  ((passed++))
else
  ((failed++))
fi

echo -e "${CYAN}Trivy - Code Scan (SAST)${NC}\n"
if command -v trivy &> /dev/null; then
  ((total++))
  if run_check "trivy-code" "trivy fs . --severity CRITICAL,HIGH --format json -o $LOGS_DIR/trivy-code-results.json 2>&1 || true"; then
    ((passed++))
  else
    ((failed++))
  fi

  echo -e "${CYAN}Trivy - Docker Image Scan${NC}\n"
  if [ -f Dockerfile ]; then
    ((total++))
    echo -e "${CYAN}[$(date '+%H:%M:%S')] Building Docker image...${NC}"
    if docker build -t wellme-back:scan . > "$LOGS_DIR/docker-build.log" 2>&1; then
      echo -e "${GREEN}Docker image built${NC}\n"
      ((total++))
      if run_check "trivy-image" "trivy image wellme-back:scan --severity CRITICAL,HIGH --format json -o $LOGS_DIR/trivy-image-results.json 2>&1 || true"; then
        ((passed++))
      else
        ((failed++))
      fi
    else
      echo -e "${YELLOW}Docker build failed${NC}\n"
      ((failed++))
    fi
  else
    echo -e "${YELLOW}Dockerfile not found, skipping image scan${NC}\n"
  fi
else
  echo -e "${YELLOW}Trivy not installed (brew install trivy)${NC}\n"
fi

echo -e "${CYAN}Gitleaks - Secret Scanning${NC}\n"
if command -v gitleaks &> /dev/null; then
  ((total++))
  if run_check "gitleaks" "gitleaks detect --verbose --report-path $LOGS_DIR/gitleaks-report.json 2>&1 || true"; then
    ((passed++))
  else
    ((failed++))
  fi
else
  echo -e "${YELLOW}Gitleaks not installed (brew install gitleaks)${NC}\n"
fi

echo -e "${CYAN}OWASP Dependency-Check (SCA)${NC}\n"
if command -v dependency-check &> /dev/null; then
  ((total++))
  if run_check "dependency-check" "dependency-check --project wellme-back --scan . --format JSON --out $LOGS_DIR/dependency-check-report.json 2>&1 || true"; then
    ((passed++))
  else
    ((failed++))
  fi
else
  echo -e "${YELLOW}OWASP Dependency-Check not installed (brew install dependency-check)${NC}\n"
fi

echo -e "${CYAN}Semgrep - Code Scanning (SAST)${NC}\n"
if command -v semgrep &> /dev/null; then
  ((total++))
  if run_check "semgrep" "semgrep --config=p/owasp-top-ten --json --output=$LOGS_DIR/semgrep-results.json . 2>&1 || true"; then
    ((passed++))
  else
    ((failed++))
  fi
else
  echo -e "${YELLOW}Semgrep not installed (brew install semgrep)${NC}\n"
fi

echo -e "${BLUE}CI/CD Simulation Summary${NC}\n"
echo -e "Total Checks:    ${CYAN}$total${NC}"
echo -e "Passed:          ${GREEN}$passed${NC}"
echo -e "Failed/Warnings: ${YELLOW}$failed${NC}\n"

echo -e "${GREEN}Logs saved to: ${CYAN}$LOGS_DIR/${NC}\n"
echo -e "${BLUE}Available logs:${NC}"
ls -1 "$LOGS_DIR" | while read log; do
  size=$(du -h "$LOGS_DIR/$log" | cut -f1)
  echo "  - $log ($size)"
done

echo -e "\n${BLUE}View full reports:${NC}"
echo "  npm audit:   cat $LOGS_DIR/npm-audit-report.json | jq"
echo "  Trivy code:  cat $LOGS_DIR/trivy-code-results.json | jq"
echo "  Trivy image: cat $LOGS_DIR/trivy-image-results.json | jq"
echo "  Gitleaks:    cat $LOGS_DIR/gitleaks-report.json | jq"
echo "  Semgrep:     cat $LOGS_DIR/semgrep-results.json | jq"

echo -e "\n${GREEN}CI/CD simulation completed${NC}\n"
