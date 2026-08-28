#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

banner() { printf '\n========== %s ==========\n' "$1"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

banner "PHP syntax"
if command -v php >/dev/null 2>&1; then
  php -l web/index.php
else
  echo "SKIP: php CLI unavailable; container smoke test performs the runtime PHP check."
fi

banner "bcrypt htpasswd"
if command -v htpasswd >/dev/null 2>&1; then
  tmp_auth="$(mktemp)"
  trap 'rm -f "$tmp_auth"' EXIT
  htpasswd -Bbn test-user 'test-password-only' > "$tmp_auth"
  grep -Eq '^test-user:\$2[aby]\$' "$tmp_auth" || fail "htpasswd output is not bcrypt"
  htpasswd -vb "$tmp_auth" test-user 'test-password-only'
  if htpasswd -vb "$tmp_auth" test-user 'wrong-password' >/dev/null 2>&1; then
    fail "wrong htpasswd password unexpectedly verified"
  fi
  echo "PASS: bcrypt creation and verification"
else
  echo "SKIP: htpasswd unavailable; it is installed in the container image."
fi

banner "Rendered read-only dashboard"
if command -v php >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp" ${tmp_auth:-}' EXIT
  mkdir -p "$tmp/storage/books.backup" "$tmp/storage/evil<script>.backup" "$tmp/runtime"
  printf 'backup-data' > "$tmp/storage/books.backup/data.zip"
  printf 'evil-data' > "$tmp/storage/evil<script>.backup/data.zip"
  now="$(date +%s)"
  cat > "$tmp/runtime/uploads.json" <<JSON
{"uploads":{"test":{"backup_name":"sync.backup","filename":"<img src=x onerror=alert(1)>.zip","bytes_received":512,"total_bytes":1024,"started_at":$now,"updated_at":$now}}}
JSON
  LNREADER_STORAGE_DIR="$tmp/storage" \
  LNREADER_RUNTIME_DIR="$tmp/runtime" \
  PUBLIC_URL="https://lnreader.example.test" \
  WEB_UI_SLUG="lnr-vault-7f3c9" \
    php web/index.php > "$tmp/dashboard.html"
  grep -Fq 'https://lnreader.example.test' "$tmp/dashboard.html" || fail "PUBLIC_URL missing from dashboard"
  grep -Fq 'books.backup' "$tmp/dashboard.html" || fail "stored backup missing from dashboard"
  grep -Fq 'sync.backup' "$tmp/dashboard.html" || fail "active upload missing from dashboard"
  grep -Fq 'evil&lt;script&gt;.backup' "$tmp/dashboard.html" || fail "backup name was not HTML-escaped"
  grep -Fq '&lt;img src=x onerror=alert(1)&gt;.zip' "$tmp/dashboard.html" || fail "active filename was not HTML-escaped"
  if grep -Fq 'evil<script>.backup' "$tmp/dashboard.html" || grep -Fq '<img src=x onerror=alert(1)>.zip' "$tmp/dashboard.html"; then
    fail "unescaped attacker-controlled text reached dashboard HTML"
  fi
  grep -Fq 'Read-only status console' "$tmp/dashboard.html" || fail "dashboard marker missing"
  if grep -Eiq '<script|javascript:' "$tmp/dashboard.html"; then
    fail "dashboard unexpectedly contains JavaScript"
  fi
  echo "PASS: dashboard renders public URL, backups and active uploads without JavaScript"
else
  echo "SKIP: PHP rendering unavailable."
fi

banner "Nginx security template"
for token in \
  'auth_basic' \
  'auth_basic_user_file' \
  'Content-Security-Policy' \
  'X-Robots-Tag' \
  'limit_req zone=lnreader_ui_auth' \
  'limit_except GET' \
  'proxy_request_buffering off'; do
  grep -Fq "$token" docker/nginx.conf.template || fail "missing nginx token: $token"
  echo "PASS: $token"
done

echo "PASS: web UI validation complete"

banner "Automatic Web UI credential lifecycle"
./scripts/webui-auth-test.sh
