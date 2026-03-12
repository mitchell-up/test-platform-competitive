#!/bin/bash
set -euo pipefail

# 원격 환경(Claude Code on the web)에서만 실행
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# gh CLI가 이미 설치되어 있으면 건너뜀
if command -v gh &>/dev/null; then
  echo "gh CLI already installed: $(gh --version | head -1)"
else
  # gh CLI 최신 안정 버전 다운로드 및 설치
  GH_VERSION="2.45.0"
  GH_INSTALL_DIR="/usr/local/bin"
  GH_TMP_DIR=$(mktemp -d)

  echo "Installing gh CLI v${GH_VERSION}..."

  curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" \
    -o "${GH_TMP_DIR}/gh.tar.gz"

  tar -xzf "${GH_TMP_DIR}/gh.tar.gz" -C "${GH_TMP_DIR}"

  # /usr/local/bin이 쓰기 가능하면 시스템 전역에 설치, 아니면 홈 디렉토리에 설치
  if [ -w "${GH_INSTALL_DIR}" ]; then
    cp "${GH_TMP_DIR}/gh_${GH_VERSION}_linux_amd64/bin/gh" "${GH_INSTALL_DIR}/gh"
    chmod +x "${GH_INSTALL_DIR}/gh"
    echo "gh CLI installed to ${GH_INSTALL_DIR}/gh"
  else
    LOCAL_BIN="${HOME}/.local/bin"
    mkdir -p "${LOCAL_BIN}"
    cp "${GH_TMP_DIR}/gh_${GH_VERSION}_linux_amd64/bin/gh" "${LOCAL_BIN}/gh"
    chmod +x "${LOCAL_BIN}/gh"
    echo "export PATH=\"${LOCAL_BIN}:\$PATH\"" >> "${CLAUDE_ENV_FILE:-/dev/null}"
    echo "gh CLI installed to ${LOCAL_BIN}/gh"
  fi

  rm -rf "${GH_TMP_DIR}"
  echo "gh CLI installation complete: $(gh --version | head -1)"
fi

# GH_TOKEN이 설정되어 있으면 gh auth login 수행
# gh CLI는 GH_TOKEN 환경변수가 있으면 자동으로 인증에 사용함
if [ -n "${GH_TOKEN:-}" ]; then
  echo "GH_TOKEN detected, logging in to GitHub CLI..."
  echo "${GH_TOKEN}" | gh auth login --with-token
  echo "gh auth login complete: $(gh auth status 2>&1 | head -1)"
  # 세션 전체에서 인증 상태 유지를 위해 환경변수 전달
  echo "export GH_TOKEN=\"${GH_TOKEN}\"" >> "${CLAUDE_ENV_FILE:-/dev/null}"
elif [ -n "${GITHUB_TOKEN:-}" ]; then
  echo "GITHUB_TOKEN detected, logging in to GitHub CLI..."
  echo "${GITHUB_TOKEN}" | gh auth login --with-token
  echo "gh auth login complete: $(gh auth status 2>&1 | head -1)"
  echo "export GH_TOKEN=\"${GITHUB_TOKEN}\"" >> "${CLAUDE_ENV_FILE:-/dev/null}"
else
  echo "⚠️  GH_TOKEN 또는 GITHUB_TOKEN 환경변수가 설정되어 있지 않습니다."
  echo "   GitHub 이슈/PR 생성을 위해 Claude Code 설정에서 GH_TOKEN을 추가해주세요."
  echo "   GitHub Personal Access Token: https://github.com/settings/tokens"
fi
