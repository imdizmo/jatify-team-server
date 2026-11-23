# Changelog

Each release names the version of each service it contains. A release's notes on GitHub are its section below.

## [Unreleased]

- **Questlog's server 0.4.0** (was 0.3.0).

## [0.1.1] - 2026-11-18

- **The library service, ShelfServer 0.6.1:** in the Docker image it no longer watches every folder under `/` before
  it starts. With a large shared library (on a network mount especially), 0.6.0 could take minutes to start, or never
  answer, and came close to its memory limit. Questlog's server stays at 0.3.0.

## [0.1.0] - 2026-11-18

The first team server: one thing to install for a team that works together with the Jatify tools.

- **Questlog's server 0.3.0:** the team's shared workspace (tasks, board, lore) and the team list (`team.json`).
- **The library service, ShelfServer 0.6.0:** the shared asset library, the maps and props teammates publish from
  Groundwork and Prop Generator, Git LFS with file locking for big game files, the team's projects, crash reports
  from the tools, and playtest logs from the game.
- **Sign-in through Tailscale:** each service knows who is calling from Tailscale, so nobody needs a password for the
  library. Roles come from the team list.
- Three ways to run it: with Docker beside Tailscale (`compose.yaml`), from a download for Linux or Windows (the
  Jatify Launcher's "Run the server on this computer"), or by hand.
- **For a machine already on the tailnet** (a NAS, a home server): `compose-host-tailscale.yaml` runs both services
  on the machine's own Tailscale, keeping its address and names, with no auth key.

### Not tested yet

- The Windows download has not been run on a real Windows machine.
