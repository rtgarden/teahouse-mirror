#!/bin/bash
# Teahouse Mirror Site - One Command Deploy
# Usage: bash deploy.sh

SERVER="159.89.129.150"
USER="rtgarden-admin"
LOCAL="/Users/rtgarden/Desktop/webme/teahouse-mirror/"
REMOTE_TMP="/tmp/teahouse/"
WEB_ROOT="/var/www/html/"

echo "=== Teahouse Deploy ==="
echo "Step 1: Uploading files..."
rsync -avz --progress --exclude 'deploy.sh' --exclude 'DEPLOY.sh' --exclude '.DS_Store' --exclude '*.py' "$LOCAL" "${USER}@${SERVER}:${REMOTE_TMP}"

if [ $? -ne 0 ]; then
    echo "ERROR: rsync failed. Check your connection."
    exit 1
fi

echo ""
echo "Step 2: Copying to web root (will ask for password)..."
ssh -t "${USER}@${SERVER}" "sudo cp -r ${REMOTE_TMP}* ${WEB_ROOT} && sudo chown -R www-data:www-data ${WEB_ROOT} && sudo chmod -R 755 ${WEB_ROOT} && echo 'Deploy complete!'"

echo ""
echo "=== Done! Check https://rtgarden.com ==="
