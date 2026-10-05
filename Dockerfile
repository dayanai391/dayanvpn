# DayanVPN — Xray (VLESS + WebSocket) behind nginx, with a landing page
FROM alpine:3.20

RUN apk add --no-cache nginx curl unzip ca-certificates

# Install latest Xray-core
RUN mkdir -p /usr/local/bin/xray /usr/local/share/xray \
    && curl -fsSL -o /tmp/Xray-linux-64.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" \
    && unzip -o /tmp/Xray-linux-64.zip -d /usr/local/bin/xray \
    && chmod +x /usr/local/bin/xray/xray \
    && rm /tmp/Xray-linux-64.zip

ENV PORT=8080

COPY config.json /etc/xray/config.json
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /srv/dayanvpn/index.html
COPY entrypoint.sh /entrypoint.sh
RUN mkdir -p /usr/share/nginx/html \
    && chmod +x /entrypoint.sh

EXPOSE 8080

CMD ["/entrypoint.sh"]
