# DayanVPN — VLESS + WebSocket + TLS on Railway (with landing page)

A branded version: anyone who opens your domain in a browser sees a **DayanVPN** page with your config link, QR code and setup instructions. Proxy clients connect through the same domain on WebSocket path `/ray`.

## How it works

```
Browser  ──▶  GET /        ──▶  nginx  ──▶  DayanVPN landing page (index.html)
Client   ──▶  WS  /ray     ──▶  nginx  ──▶  Xray (VLESS)  ──▶  internet
```

- **nginx** listens on Railway's `PORT` and splits traffic by path.
- **Xray** listens only on `127.0.0.1:10086` (not exposed publicly).
- **entrypoint.sh** injects your UUID from `config.json` into the landing page at startup — you only ever edit the UUID in one place.
- TLS is terminated by Railway's proxy (your `https://…up.railway.app` domain works out of the box).

## Files

| File | Purpose |
|------|---------|
| `config.json` | Xray server config (VLESS + WS, path `/ray`) — **the UUID lives here** |
| `nginx.conf` | Routes `/` → landing page, `/ray` → Xray |
| `index.html` | DayanVPN landing page (UUID auto-injected) |
| `entrypoint.sh` | Injects UUID, aligns ports, starts both services |
| `Dockerfile` | Builds nginx + latest Xray-core |

## Deploy to Railway

1. Create a new **private** GitHub repo.
2. Upload all 5 code files (`config.json`, `nginx.conf`, `index.html`, `entrypoint.sh`, `Dockerfile`) — or via git:

```powershell
git init
git add .
git commit -m "DayanVPN"
git branch -M main
git remote add origin https://github.com/YOUR-USER/dayanvpn.git
git push -u origin main
```

3. **Railway → New Project → Deploy from GitHub repo** → select the repo. Railway builds the Dockerfile automatically.
4. **Networking tab → Generate Domain** → you get e.g. `dayanvpn-abc123.up.railway.app`.
5. Open that URL in a browser — you should see the **DayanVPN** page with a live config link (built from your real domain and UUID automatically).

## Connecting a client

Easiest: open your domain in a browser and hit **Copy config**, then import from clipboard in v2rayNG / Nekobox / Streisand / Hiddify. Or scan the QR code.

Manual share link format:

```
vless://YOUR-UUID@your-domain.up.railway.app:443?encryption=none&security=tls&sni=your-domain.up.railway.app&type=ws&host=your-domain.up.railway.app&path=%2Fray#DayanVPN
```

## Multiple servers + one subscription link

Run the same project in several Railway regions so users can pick the fastest location, all behind a single subscription URL.

1. **Deploy the service once** (steps above) → generate a domain, note it (e.g. `...up.railway.app` → tag `US`).
2. **Add more servers:** in your Railway project click **+ Create → GitHub repo**, pick the **same repo** again → a second service builds from identical code (same UUID). For each new service:
   - **Settings → Region** → pick a different region (e.g. Europe, Asia).
   - **Networking tab → Generate Domain** → note its domain.
3. **Tell every service about all servers:** open the **Variables** tab on **each** service and add one variable:
   ```
   SERVERS = us-app.up.railway.app:US,eu-app.up.railway.app:EU,ap-app.up.railway.app:AP
   ```
   Same value everywhere — format is `domain:TAG` separated by commas. Saving a variable triggers an automatic redeploy.
4. **Subscription URL:** `https://any-one-of-your-domains/sub` — import it in your client (v2rayNG: *Settings → Online subscriptions*; Hiddify: *Add profile → URL*). The client now shows all servers, named `DayanVPN-US`, `DayanVPN-EU`, … The landing page also shows the subscription link automatically once configured.

Tips: for users in Iran, EU regions usually beat US in latency; let each user test and keep the fastest. Adding servers does not raise the speed of a single connection — it adds *choices*.

## Troubleshooting

- **404 on the domain** → the repo doesn't contain these files (old version deployed). Verify the build log shows `apk add ... nginx` and `COPY index.html`.
- **Landing page loads but VPN doesn't connect** → UUID mismatch: the UUID shown at the bottom of the page is injected from `config.json` — it must match what your client uses (if you import from the page's link, it always will).
- **QR doesn't appear** → the page loads a QR library from cdnjs; if blocked on your network, use the Copy button instead.

## Security notes

- Keep the repo **private** — `config.json` contains your UUID, which is effectively the password to your server.
- Anyone you share the page URL with can get the config — treat the domain as a secret.
