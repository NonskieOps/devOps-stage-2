# generate-nginx.sh
#!/bin/bash
set -e

if [ -f .env ]; then
  source .env
else
  echo "Error: .env not found. Copy .env.example to .env first."
  exit 1
fi

if [ "$ACTIVE_POOL" = "blue" ]; then
  primary='  server app_blue:8080 max_fails=1 fail_timeout=5s;'
  backup='  server app_green:8080 backup max_fails=1 fail_timeout=5s;'
elif [ "$ACTIVE_POOL" = "green" ]; then
  primary='  server app_green:8080 max_fails=1 fail_timeout=5s;'
  backup='  server app_blue:8080 backup max_fails=1 fail_timeout=5s;'
else
  echo "Error: ACTIVE_POOL must be 'blue' or 'green' in .env"
  exit 1
fi

sed -e "s|#PRIMARY|${primary}|g" -e "s|#BACKUP|${backup}|g" nginx.conf.template > nginx.conf

echo "Generated nginx.conf: Primary=$ACTIVE_POOL (Backup=$( [ "$ACTIVE_POOL" = "blue" ] && echo "green" || echo "blue" ))"