# Fluxer on DigitalOcean for `dawe.dev`

This bundle is prepared for:

- `https://fluxer.dawe.dev`
- `https://lk.dawe.dev`

It assumes a single Ubuntu 24.04 DigitalOcean Droplet, Docker Compose, a DigitalOcean load balancer, and Cloudflare-managed DNS.

## What This Bundle Contains

- `docker-compose.yml`: Traefik, Fluxer, Valkey, Meilisearch, LiveKit, and NATS
- `config/config.json.template`: Fluxer config template
- `config/livekit.yaml.template`: LiveKit config template
- `scripts/generate-secrets.sh`: prints random secrets and VAPID keys
- `scripts/render-configs.sh`: renders the two config files from `.env`

## Recommended Droplet

- 4 vCPU
- 8 GB RAM
- 100 GB SSD
- Ubuntu 24.04 x64

## Cloudflare

Create two proxied DNS records pointing to your DigitalOcean load balancer IP:

- `fluxer.dawe.dev` -> your load balancer IPv4
- `lk.dawe.dev` -> your load balancer IPv4

Recommended Cloudflare settings:

- SSL/TLS mode: `Full`
- Rocket Loader: `Off`
- Auto Minify for JavaScript: `Off`
- Email Address Obfuscation: `Off`

This bundle does not require Cloudflare API access. Traefik serves the origin directly and Cloudflare terminates public TLS at the edge.

## DigitalOcean Firewall

Allow:

- `22/tcp` from your IP only
- `80/tcp` from anywhere
- `443/tcp` from anywhere
- `7881/tcp` from anywhere
- `3478/udp` from anywhere
- `50000-50100/udp` from anywhere

## Droplet Bootstrap

Run this on the Droplet:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl git jq gettext-base
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<'EOF'
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Log out and back in once after adding your user to the `docker` group.

## Prepare The Deploy Directory

```bash
mkdir -p /srv/fluxer
cd /srv/fluxer
```

Copy this bundle to the Droplet, then:

```bash
cp .env.example .env
chmod +x ./scripts/*.sh
./scripts/generate-secrets.sh
./scripts/render-configs.sh
```

## Fluxer Source Build

Clone Fluxer and build the app image:

```bash
cd /srv/fluxer
git clone https://github.com/fluxerapp/fluxer.git
cd fluxer
git checkout refactor
```

Before building, apply the upstream fixes from your deployment notes:

- Dockerfile package copy list must match the monorepo
- add Rust and `wasm-pack` to `fluxer_server/Dockerfile`
- relax `.dockerignore` for locales, emojis, and build scripts
- set `FLUXER_CONFIG` during the frontend build
- fix `FLUXER_CDN_ENDPOINT` empty-string handling in `fluxer_app/rspack.config.mjs`
- fix the Docker `ENTRYPOINT`
- add admin CSS build if needed
- add `fluxerstatic.com` to the monolith CSP if you keep those external assets
- apply the SSO fixes if you plan to use OIDC

Then build:

```bash
cd /srv/fluxer/fluxer
docker build \
  -t fluxer-server:local \
  --build-arg BASE_DOMAIN="fluxer.dawe.dev" \
  --build-arg FLUXER_CDN_ENDPOINT="" \
  --build-arg INCLUDE_NSFW_ML=true \
  -f fluxer_server/Dockerfile .
```

## Start The Stack

From the directory containing this bundle:

```bash
cd /srv/fluxer
docker compose up -d
```

## Verify

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
curl -s https://fluxer.dawe.dev/_health | jq
curl -sI https://fluxer.dawe.dev/
curl -sI https://lk.dawe.dev/
```

## DNS And Cutover

Point both proxied Cloudflare records at the load balancer IP, not the Droplet IP. The load balancer should forward:

- `80/tcp` -> backend `80/tcp`
- `443/tcp` -> backend `443/tcp`

LiveKit media uses the Droplet IP directly for `7881/tcp`, `3478/udp`, and `50000-50100/udp`.
