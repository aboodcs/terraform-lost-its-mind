#!/bin/bash

set -euxo pipefail

exec > >(tee -a /var/log/terraform-bootstrap.log) 2>&1

for attempt in {1..6}; do
  if curl -s --max-time 5 https://yum.oracle.com >/dev/null 2>&1; then
    echo "Internet connection is ready."
    break
  fi

  echo "Waiting for network... attempt $${attempt}/6"
  sleep 10
done

if command -v dnf >/dev/null 2>&1; then
  dnf install -y nginx
elif command -v yum >/dev/null 2>&1; then
  yum install -y nginx
else
  echo "ERROR: Neither dnf nor yum was found."
  exit 1
fi

if ! command -v nginx >/dev/null 2>&1; then
  echo "ERROR: nginx installation failed."
  exit 1
fi

cat > /usr/share/nginx/html/index.html <<'HTML'
${index_html}
HTML

systemctl enable nginx
systemctl restart nginx

if systemctl is-active --quiet firewalld; then
  firewall-cmd --permanent --add-service=http
  firewall-cmd --reload
fi
