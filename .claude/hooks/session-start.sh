#!/bin/bash
set -euo pipefail

# 원격 환경(Claude Code on the web)에서만 실행
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# gh CLI가 이미 설치되어 있으면 건너뜀
if command -v gh &>/dev/null; then
  echo "gh CLI already installed: $(gh --version | head -1)"
  exit 0
fi

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
