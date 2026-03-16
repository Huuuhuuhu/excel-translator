#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
USER_NAME="$(id -un)"
HOME_DIR="${HOME}"
if [[ $# -gt 0 ]]; then
  PORTS=("$@")
else
  PORTS=(8501 8502 8503)
fi
TEMPLATE_SRC="$APP_DIR/deploy/systemd/excel-translator@.service"
TEMPLATE_DEST="/etc/systemd/system/excel-translator@.service"

if [[ ! -x "$APP_DIR/.venv/bin/streamlit" ]]; then
  echo "Missing virtualenv or streamlit binary: $APP_DIR/.venv/bin/streamlit" >&2
  exit 1
fi

TMP_FILE="$(mktemp)"
sed \
  -e "s#__USER__#${USER_NAME}#g" \
  -e "s#__HOME_DIR__#${HOME_DIR//\/\\}#g" \
  -e "s#__APP_DIR__#${APP_DIR//\/\\}#g" \
  "$TEMPLATE_SRC" > "$TMP_FILE"

sudo install -m 0644 "$TMP_FILE" "$TEMPLATE_DEST"
rm -f "$TMP_FILE"

sudo systemctl daemon-reload

for port in "${PORTS[@]}"; do
  sudo systemctl enable --now "excel-translator@${port}.service"
done

echo "Installed and started: ${PORTS[*]}"
echo "Check status with: systemctl status excel-translator@8501.service"
