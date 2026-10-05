#!/bin/sh
set -e

PORT="${PORT:-8080}"

# 1. Extract the UUID from the Xray config so the landing page always shows the real one
UUID=$(grep -o '"id": *"[^"]*"' /etc/xray/config.json | head -n1 | sed 's/.*"\([0-9a-fA-F-]\{36\}\)".*/\1/')

# 2. Write the landing page with the UUID baked in
sed "s/__UUID__/${UUID}/g" /srv/dayanvpn/index.html > /usr/share/nginx/html/index.html

# 3. Point nginx at Railway's injected PORT
sed -i "s/listen [0-9]*;/listen ${PORT};/" /etc/nginx/nginx.conf

# 4. Start Xray in the background, then nginx in the foreground
/usr/local/bin/xray/xray run -c /etc/xray/config.json &
exec nginx -g "daemon off;"
