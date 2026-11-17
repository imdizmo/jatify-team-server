#!/usr/bin/env bash
# Prints compose.yaml for one release, pinned to its images: scripts/compose.sh <team server> <shelf> <questlog>
set -euo pipefail
v="$1"; shelf="$2"; questlog="$3"
cat <<YAML
# Jatify team server $v: Questlog's server $questlog and the library service (ShelfServer) $shelf, beside Tailscale.
# Put TS_AUTHKEY (and TEAM_NAME if you change it) in a .env file next to this one; see the guide in README.md.
services:
  tailscale:
    image: tailscale/tailscale:v1.104.7
    hostname: \${TEAM_NAME:-team}       # the server's name on your tailnet
    environment:
      TS_AUTHKEY: \${TS_AUTHKEY}
      TS_STATE_DIR: /var/lib/tailscale
      TS_SOCKET: /var/run/tailscale/tailscaled.sock
      TS_USERSPACE: "false"            # callers arrive with their own tailnet address, so the services know who they are
    cap_add: [NET_ADMIN]
    devices: [/dev/net/tun:/dev/net/tun]
    volumes:
      - tailscale-state:/var/lib/tailscale
      - tailscale-socket:/var/run/tailscale
    restart: unless-stopped

  questlog:
    image: ghcr.io/imdizmo/questlog-server:$questlog
    network_mode: service:tailscale
    depends_on: [tailscale]
    environment:
      PORT: "8780"
      JT_HOST: 0.0.0.0                 # inside Tailscale's network: only the tailnet reaches it
      JT_HOSTS: \${TEAM_NAME:-team}:8780,\${TEAM_NAME:-team}.\${TAILNET:-}:8780
      JT_DB: /data/jt.db
      JT_FILES: /data/files
      JT_TEAM_FILE: /team/team.json
      JT_BACKUP_BEFORE_MIGRATE: "1"
      JT_TAILSCALE_AUTH: "1"
      JT_TAILSCALE_SOCKET: /var/run/tailscale/tailscaled.sock
      JATIFY_TEAM_SERVER: "$v"
    volumes:
      - tailscale-socket:/var/run/tailscale:ro
      - ./data/questlog:/data
      - ./data/team:/team
    restart: unless-stopped

  shelf:
    image: ghcr.io/imdizmo/shelf-server:$shelf
    network_mode: service:tailscale
    depends_on: [tailscale]
    environment:
      JATIFY_TEAM_SERVER: "$v"
    command: ["--listen", "tailscale:8781", "--store", "/data", "--team", "/team/team.json"]
    # to share an Asset Shelf library, add: , "--library", "/library"  and the volume below
    volumes:
      - tailscale-socket:/var/run/tailscale:ro
      - ./data/shelf:/data
      - ./data/team:/team:ro
      # - /path/to/library:/library:ro
    restart: unless-stopped            # both start again until Tailscale is up

volumes:
  tailscale-state:
  tailscale-socket:
YAML
