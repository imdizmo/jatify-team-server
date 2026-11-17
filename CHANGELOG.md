# Changelog

Each release names the version of each service it contains. A release's notes on GitHub are its section below.

## [0.1.0] - not released yet

The first team server: one thing to install for a team that works together with the Jatify tools.

- **Questlog's server 0.3.0:** the team's shared workspace (tasks, board, lore) and the team list (`team.json`).
- **The library service, ShelfServer 0.5.0:** the shared asset library, the maps and props teammates publish from
  Groundwork and Prop Generator, Git LFS with file locking for big game files, the team's projects, and crash reports
  from the tools.
- **Sign-in through Tailscale:** each service knows who is calling from Tailscale, so nobody needs a password for the
  library. Roles come from the team list.
- Three ways to run it: with Docker beside Tailscale (`compose.yaml`), from a download for Linux or Windows (the
  Jatify Launcher's "Run the server on this computer"), or by hand.

### Not tested yet

- The Windows download has not been run on a real Windows machine.
