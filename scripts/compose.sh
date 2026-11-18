#!/usr/bin/env bash
# Prints compose.yaml for one release, pinned to its images: scripts/compose.sh [--host-tailscale] <team server> <shelf> <questlog>
# --host-tailscale prints compose-host-tailscale.yaml instead: for a machine that already runs Tailscale itself.
set -euo pipefail
host=0; [[ "${1:-}" == --host-tailscale ]] && { host=1; shift; }
v="$1"; shelf="$2"; questlog="$3"
if (( host )); then cat <<YAML
# Jatify team server $v: Questlog's server $questlog and the library service (ShelfServer) $shelf, on a machine that
# already runs Tailscale (a NAS, a home server). No Tailscale container and no auth key: both services use the host's
# network and its tailscaled, so the server keeps the machine's own tailnet address and names.
# Put TEAM_ADDRESS, TEAM_NAME and TAILNET (and the folders, if you change them) in a .env file next to this one; see
# "A machine that already runs Tailscale" in README.md.
# The machine must be a tagged device (Tailscale admin console: Edit ACL tags, e.g. tag:server). On the host's network a
# program on the machine itself calls from the machine's own address; the services treat a tagged device as nobody,
# but on an untagged machine it would count as the machine's owner.
services:
  questlog:
    image: ghcr.io/imdizmo/questlog-server:$questlog
    network_mode: host
    user: "\${RUN_AS:-1000:1000}"       # the owner of the data folders
    environment:
      PORT: "8780"
      JT_HOST: \${TEAM_ADDRESS:?the machine's 100.x tailnet address}   # never 0.0.0.0 on the host's network
      JT_HOSTS: \${TEAM_ADDRESS}:8780,\${TEAM_NAME:?the machine's tailnet name}:8780,\${TEAM_NAME}.\${TAILNET:?your tailnet, like example.ts.net}:8780
      JT_DB: /data/jt.db
      JT_FILES: /data/files
      JT_TEAM_FILE: /team/team.json
      JT_BACKUP_BEFORE_MIGRATE: "1"
      JT_TAILSCALE_AUTH: "1"
      JT_TAILSCALE_SOCKET: /var/run/tailscale/tailscaled.sock
      NODE_OPTIONS: --max-old-space-size=\${QUESTLOG_HEAP_MB:-512}
      JATIFY_TEAM_SERVER: "$v"
    volumes:
      - /var/run/tailscale:/var/run/tailscale:ro   # the folder, so a restarted tailscaled's new socket is seen
      - \${QUESTLOG_DATA:-./data/questlog}:/data
      - \${TEAM_DIR:-./data/team}:/team
    mem_limit: \${QUESTLOG_MEMORY:-768m}
    restart: unless-stopped

  shelf:
    image: ghcr.io/imdizmo/shelf-server:$shelf
    network_mode: host
    user: "\${RUN_AS:-1000:1000}"
    environment:
      JATIFY_TEAM_SERVER: "$v"
    command: ["--listen", "tailscale:8781", "--store", "/data", "--team", "/team/team.json", "--projects", "/data/projects.json"]
    # to share an Asset Shelf library (its index/ and packs/), add: , "--library", "/library"  and the volume below
    volumes:
      - /var/run/tailscale:/var/run/tailscale:ro
      - \${SHELF_DATA:-./data/shelf}:/data
      - \${TEAM_DIR:-./data/team}:/team:ro
      # - \${LIBRARY}:/library:ro
    mem_limit: \${SHELF_MEMORY:-512m}
    restart: unless-stopped
YAML
exit 0
fi
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
    command: ["--listen", "tailscale:8781", "--store", "/data", "--team", "/team/team.json", "--projects", "/data/projects.json"]
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
