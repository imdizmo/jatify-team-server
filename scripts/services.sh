#!/usr/bin/env bash
# Prints services.json: how a launcher starts each service from the unpacked folder ("run the server on this
# computer"). {listen} is this machine's tailnet address, {data} the data folder; paths are relative to the folder.
#   scripts/services.sh <team server version> <shelf version> <questlog version> [".exe"]
set -euo pipefail
v="$1"; shelf="$2"; questlog="$3"; exe="${4:-}"
cat <<JSON
{
  "schema": 1,
  "version": "$v",
  "services": [
    {
      "service": "questlog", "version": "$questlog", "port": 8780,
      "run": ["questlog/runtime/node$exe", "questlog/server/server.mjs"],
      "env": {
        "PORT": "8780", "JT_HOST": "{listen}", "JT_HOSTS": "{listen}:8780",
        "JT_DB": "{data}/questlog/jt.db", "JT_FILES": "{data}/questlog/files", "JT_WEB": "questlog/web",
        "JT_TEAM_FILE": "{data}/team/team.json", "JT_BACKUP_BEFORE_MIGRATE": "1", "JT_TAILSCALE_AUTH": "1",
        "JATIFY_TEAM_SERVER": "$v"
      },
      "ready": "QUESTLOG_LISTENING", "health": "/healthz"
    },
    {
      "service": "shelf", "version": "$shelf", "port": 8781,
      "run": ["shelf/bin/ShelfServer$exe", "--listen", "{listen}:8781", "--store", "{data}/shelf", "--team", "{data}/team/team.json", "--projects", "{data}/shelf/projects.json"],
      "env": { "JATIFY_TEAM_SERVER": "$v", "DOTNET_GCHeapHardLimit": "0x10000000" },
      "ready": "SHELF_LISTENING", "health": "/healthz"
    }
  ]
}
JSON
