#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Local Security Checks${NC}\n"

echo -e "${BLUE}[1/6] Running npm audit...${NC}"
if npm audit --audit-level=moderate; then
  echo -e "${GREEN}npm audit passed${NC}\n"
else
  echo -e "${YELLOW}npm audit found vulnerabilities (check report above)${NC}\n"
fi

echo -e "${BLUE}[2/6] Running ESLint...${NC}"
if npm run lint 2>/dev/null; then
  echo -e "${GREEN}ESLint passed${NC}\n"
else
  echo -e "${YELLOW}ESLint found issues${NC}\n"
fi

echo -e "${BLUE}[3/6] Running TypeScript type check...${NC}"
if npm run type-check 2>/dev/null; then
  echo -e "${GREEN}TypeScript passed${NC}\n"
else
  echo -e "${YELLOW}TypeScript found type errors${NC}\n"
fi

echo -e "${BLUE}[4/6] Checking for secrets (Gitleaks)...${NC}"
if command -v gitleaks &> /dev/null; then
  if gitleaks detect --verbose 2>/dev/null | grep -q "no leaks found"; then
    echo -e "${GREEN}No secrets detected${NC}\n"
  else
    echo -e "${RED}Secrets detected! Do not push!${NC}\n"
    exit 1
  fi
else
  echo -e "${YELLOW}Gitleaks not installed (install with: brew install gitleaks)${NC}\n"
fi

echo -e "${BLUE}[5/6] Scanning with Trivy (if available)...${NC}"
if command -v trivy &> /dev/null; then
  if trivy fs . --severity CRITICAL,HIGH 2>/dev/null | grep -q "No vulnerabilities detected"; then
    echo -e "${GREEN}Trivy passed${NC}\n"
  else
    echo -e "${YELLOW}Trivy found vulnerabilities${NC}\n"
  fi
else
  echo -e "${YELLOW}Trivy not installed (install with: brew install trivy)${NC}\n"
fi

echo -e "${BLUE}[6/6] Building Docker image (if available)...${NC}"
if [ -f "Dockerfile" ]; then
  if docker build -t wellme-back:local . 2>&1 | tail -5; then
    echo -e "${GREEN}Docker build succeeded${NC}\n"
  else
    echo -e "${YELLOW}Docker build had issues${NC}\n"
  fi
else
  echo -e "${YELLOW}No Dockerfile found${NC}\n"
fi

echo -e "${GREEN}Local security checks completed${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "  1. Review any warnings above"
echo "  2. Fix issues if necessary"
echo "  3. Run: git add ."
echo "  4. Run: git commit -m 'commit message'"
echo "  5. Run: git push origin <branch>"
echo ""
echo -e "${BLUE}The GitHub Actions pipeline will run additional checks:${NC}"
echo "  - CodeQL (SAST)"
echo "  - Trivy Code & Image (SAST + Container)"
echo "  - OWASP Dependency-Check (SCA)"
echo "  - TruffleHog (Secret Scanning)"
echo "  - Gitleaks (Secret Scanning)"
echo "  - Semgrep (SAST)"
