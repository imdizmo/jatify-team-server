# Jatify team server

One server for a team that works together with the Jatify tools. It runs two services side by side:

| Service | Port | What it does |
|---|---|---|
| Questlog's server | 8780 | The team's shared workspace (tasks, board, lore), and the team list: who is on the team and their role |
| The library service (ShelfServer, from Asset Shelf) | 8781 | The shared asset library, maps and props published from Groundwork and Prop Generator, Git LFS with file locking, the team's projects, crash reports |

Nobody signs in with a password for the library. The team server runs on your [Tailscale](https://tailscale.com)
network, asks Tailscale who is calling, and looks them up in the team list. Tools that aren't connected to a team
server keep working on their own, as before.

The code of each service lives in its tool's repository ([questlog](https://github.com/imdizmo/questlog),
[asset-shelf](https://github.com/imdizmo/asset-shelf/tree/main/server)); this repository packages the two, pinned to
tested versions (`services/`). Each release says which versions it holds.

## Three ways to run it

1. **The Jatify Launcher:** Server tab > "Run the server on this computer". It downloads the release for your system
   and runs both services while the Launcher is open.
2. **Docker,** on a home server, a NAS with Docker, or a small cloud machine. See below.
3. **By hand:** unpack the download for your system. `services.json` lists how each service starts.

## Docker

Each release has a `compose.yaml` pinned to its images: `ghcr.io/imdizmo/questlog-server` and
`ghcr.io/imdizmo/shelf-server`, beside Tailscale's own `tailscale/tailscale`.

1. **An auth key.** In the Tailscale admin console, under Settings > Keys, make an auth key. Put it in a file named
   `.env` next to `compose.yaml`, together with your tailnet's name (shown in the admin console under DNS) and, if
   you like, the server's name:

   ```
   TS_AUTHKEY=tskey-auth-...
   TAILNET=your-tailnet.ts.net
   TEAM_NAME=team
   ```

2. **Data folders,** owned by the services' users (Questlog runs as 10001, the library service as 1654):

   ```sh
   mkdir -p data/questlog data/shelf data/team
   sudo chown 10001:10001 data/questlog data/team && sudo chown 1654:1654 data/shelf
   ```

3. **Start it:**

   ```sh
   docker compose up -d
   docker compose logs     # QUESTLOG_LISTENING 8780, SHELF_LISTENING 8781
   ```

4. **First run:** open `http://team:8780` from a device on your tailnet and set up Questlog. You become the owner.
   Everyone else asks to join from Questlog, and you approve them on its Members page. That writes the team list,
   which the library service reads.

Point the tools at the server's name (`team`) or its 100.x address. The ports are fixed.

**Updating:** download the new release's `compose.yaml`, then run `docker compose pull && docker compose up -d`. Your
data stays in `data/`. Questlog backs up its database before upgrading it.

**Backups:** copy `data/`. Copying while it runs is fine if you skip dot-files; for an exact copy, stop it first.

**Why `TS_USERSPACE: "false"`:** in Tailscale's userspace mode every caller would arrive from 127.0.0.1, and the
services would recognise nobody.

### A machine that already runs Tailscale

On a NAS or home server that is already on your tailnet, use the release's `compose-host-tailscale.yaml` instead
(rename it to `compose.yaml`). It has no Tailscale container and needs no auth key: both services use the machine's
network and its own tailscaled, so the server keeps the machine's tailnet address and names, and anything already
pointing at them (tools, a game repo's `.lfsconfig`) keeps working. Its `.env`:

```
TEAM_ADDRESS=100.x.y.z         # the machine's tailnet address: the services listen only there
TEAM_NAME=my-nas               # its tailnet name
TAILNET=your-tailnet.ts.net
RUN_AS=1000:1000               # the user that owns the data folders (both services run as it)
# where the data is, if not ./data/...:
# QUESTLOG_DATA=/path/questlog-data   SHELF_DATA=/path/shelf-data   TEAM_DIR=/path/team
# QUESTLOG_MEMORY=768m  QUESTLOG_HEAP_MB=512  SHELF_MEMORY=512m   (enough on a 2 GB machine)
```

**Tag the machine first** (in the admin console, Machines > Edit ACL tags, e.g. `tag:server`). With the host's
network, a program running on the machine itself reaches the services from the machine's own address. The services
treat a tagged device as nobody, but on an untagged machine every local program would count as the machine's owner.

`/var/run/tailscale` is mounted read only, so the services can ask tailscaled who is calling. To share an Asset Shelf
library, uncomment its lines in the shelf service and set `LIBRARY`. Moving from a scripted install: stop it, copy
its data folders, point the variables above at them (Questlog's `secret.key` must come along, or everyone is signed
out), and `docker compose up -d`.

## Building a release

`scripts/build.sh <linux-x64|linux-arm64|win-x64>` builds one system's download (.NET 10 SDK, Node and pnpm needed).
A tag `v<VERSION>` with its section in `CHANGELOG.md` publishes the downloads for all three systems, `SHA256SUMS`,
`services.json`, `compose.yaml` and both images.
