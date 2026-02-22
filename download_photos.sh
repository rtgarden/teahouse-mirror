#!/bin/bash
# Download photos from Ning storage to droplet
# Usage: bash download_photos.sh manifest.tsv

MANIFEST="${1:-manifest.tsv}"
BASEDIR="/var/www/html/photos/downloaded"
DONE=0
SKIP=0
FAIL=0
TOTAL=$(wc -l < "$MANIFEST")

echo "Starting download of $TOTAL photos..."
echo "Base directory: $BASEDIR"

while IFS=$'\t' read -r storage_id contributor_dir filename; do
  # Skip empty lines
  [ -z "$storage_id" ] && continue
  
  # Create contributor directory
  mkdir -p "$BASEDIR/$contributor_dir"
  
  DEST="$BASEDIR/$contributor_dir/$filename"
  
  # Skip if already exists
  if [ -f "$DEST" ]; then
    SKIP=$((SKIP + 1))
    continue
  fi
  
  # Download from Ning storage
  URL="https://storage.ning.com/topology/rest/1.0/file/get/${storage_id}?profile=original"
  HTTP_CODE=$(curl -sL -w "%{http_code}" -o "$DEST" "$URL")
  
  if [ "$HTTP_CODE" = "200" ] && [ -s "$DEST" ]; then
    DONE=$((DONE + 1))
  else
    rm -f "$DEST"
    FAIL=$((FAIL + 1))
    echo "FAIL [$HTTP_CODE]: $contributor_dir/$filename"
  fi
  
  # Progress every 50
  PROCESSED=$((DONE + SKIP + FAIL))
  if [ $((PROCESSED % 50)) -eq 0 ]; then
    echo "Progress: $PROCESSED/$TOTAL (downloaded: $DONE, skipped: $SKIP, failed: $FAIL)"
  fi
  
  # Rate limit
  sleep 0.2
done < "$MANIFEST"

echo ""
echo "=== COMPLETE ==="
echo "Downloaded: $DONE"
echo "Skipped (existing): $SKIP"  
echo "Failed: $FAIL"
echo "Total processed: $((DONE + SKIP + FAIL))"
