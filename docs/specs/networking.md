# Spec: Networking & Multiplayer

**Status:** Approved (architecture) · **Last updated:** 2026-11-01

## 1. Goals

- **Single player and 1–4 player co-op**, with multiplayer optional but built in natively.
- **Players host their own games.** No dependency on Steam networking, "play with friends" or relays. Steam may be used later for distribution only.
- **No extra latency in single player**, and **one code path** for both modes.

## 2. Core principle: single player is a local host with one player

- **Every game runs a host.** In single player, the local machine is the host and the only player.
- **There is exactly one simulation path.** Gameplay code never branches on "single player vs. multiplayer"; it only asks about authority (`multiplayer.is_server()`, or whether this peer owns this player).
- **Godot's default `OfflineMultiplayerPeer`** already acts as a server with peer ID 1, so solo play needs no network socket.

## 3. Hosting modes

| Mode | Description |
|---|---|
| **Solo** | Local host, no socket |
| **Listen server** | A player clicks "Spiel hosten" and plays on the host. Others join |
| **Dedicated server** | The same project exported headless (`--headless`, `dedicated_server` feature tag) for a home server or VPS |

## 4. Connectivity

| Feature | MVP | Notes |
|---|---|---|
| **UPnP** | yes | The host opens the port on its router automatically via Godot's `UPNP` class, and removes the mapping on shutdown. The UI shows whether it worked |
| **Join by IP:port** | yes | The fallback, and the method for dedicated servers |
| **LAN discovery** | yes | The host announces itself via a UDP broadcast (`PacketPeerUDP`), and clients list the games they find |
| Join codes / punch-through | later | A small optional lobby server that only helps players find each other. It never relays game traffic |

- **Transport:** `ENetMultiplayerPeer` (UDP).
- **Port:** configurable; the default is still open.
- **Web builds** can't use ENet, so there's **no multiplayer in web builds**.

## 5. Authority model: host-authoritative

**The host owns and simulates:**
- enemies (spawning, AI, movement)
- damage and deaths
- drops and pickups
- the Brandmauer
- the wave timer and wave state
- Späti stock and transactions
- Zusammenhalt, Koalitionskasse and votes
- every random roll

**Clients send only:**
- inputs (movement vector; aiming is automatic)
- requests (buy, reroll, repair, vote, revive), which the host validates

## 6. Sync strategy

- **Own player:** clients predict their own movement and reconcile against host corrections, so the character stays responsive at around 80 ms of ping.
- **Other players and enemies:** clients interpolate between snapshots with a buffer of about 100 ms.
- **Seed-based spawns:**
  - Each run has a seed, and each wave derives its spawn schedule from (run seed, wave index).
  - Clients compute the schedule locally. The host only sends corrections, not every spawn.
- **Projectiles are never synced one by one.**
  - The host sends fire events (weapon, origin, direction, a seed for spread), and clients simulate the projectiles locally.
  - Hits are decided only by the host.
- **Snapshots:**
  - The host sends enemy positions and HP at 15–20 Hz, quantized and delta-compressed.
  - The physics tick stays at 60 Hz.
- **No full lockstep.** Godot physics isn't deterministic, so the seed only drives schedules and random numbers. The host's state always wins.

## 7. Session lifecycle

1. **Lobby:** players join and pick their characters, and the group picks the Organisation and Umfrage level. The host starts the run.
2. **Handshake:** the client sends a protocol and game version. A mismatch is rejected with a clear message.
3. **Joining mid-run:** not in the MVP. Lobby only.
4. **A client disconnects:** their character is removed and the enemy scaling adjusts at the start of the next wave.
5. **The host disconnects:** the run ends. There's no host migration in the MVP.

## 8. Saves & trust

- **Meta progression is saved locally on each player's machine.** Hosts never store client progress.
- **Unlocks are checked client-side** when a player picks a character, and the host accepts the choice.
- **Trust model:** co-op among friends. The host validates gameplay requests for consistency, but there's **no anti-cheat**.

## 9. Open items

- Default port number.
- Target bandwidth per client and the maximum number of enemies on screen.
- When to build join codes / punch-through.
