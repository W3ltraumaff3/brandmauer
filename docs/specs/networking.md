# Spec: Networking & Multiplayer

**Status:** Approved (architecture), implemented · **Last updated:** 2026-11-01

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
| **Dedicated server** | The same project exported headless (`--headless`, `dedicated_server` feature tag) for a home server or VPS (§9) |

## 4. Connectivity

| Feature | MVP | Notes |
|---|---|---|
| **UPnP** | yes | The host opens the port on its router automatically via Godot's `UPNP` class, and removes the mapping on shutdown. The UI shows whether it worked |
| **Join by IP:port** | yes | The fallback, and the method for dedicated servers |
| **LAN discovery** | yes | The host announces itself via a UDP broadcast (`PacketPeerUDP`), and clients list the games they find |
| Join codes / punch-through | later | A small optional lobby server that only helps players find each other. It never relays game traffic |

- **Transport:** `ENetMultiplayerPeer` (UDP), with ENet's **range-coder compression** on both ends.
- **Port:** UDP **24713** by default (`Net.PORT`). It's configurable in the host dialog and with `--port=N`, and `Net.active_port` holds the port in use. LAN discovery uses **24714** (`PORT + 1`).
- **Web builds** can't use ENet, so there's **no multiplayer in web builds**.

### 4.1 UPnP
- `UPNP.discover()` and `add_port_mapping(port, port, "Brandmauer", "UDP")` run on a worker `Thread`, so the UI never freezes.
- When the thread finishes, `Net.upnp_status` becomes `"ok"` or `"failed: <step> (<code>)"`, and `lobby_changed` fires. The status stays `""` while the thread is running.
- The mapping is removed in `Net.leave()` and on quit. A mapping that only finishes after the player has already left is removed right away.
- Godot logs a refused mapping as an engine error (`Couldn't add port mapping`). The game handles it as `failed: mapping (…)`.

### 4.2 LAN discovery
- **Host:** once per second, the host (listen or dedicated) broadcasts `BRANDMAUER|<protocol>|<name>|<port>|<players>` (UTF-8) to `255.255.255.255:24714`.
- **Client:** `Net.start_lan_discovery()` binds a `PacketPeerUDP` listener on 24714 and fills `Net.lan_games` with `[{name, ip, port, players}]`:
  - entries are deduplicated by `ip:port` and expire after 4 s
  - announcements with another protocol version are ignored
  - `lan_games_changed` fires on every change
- **Bind failure:** if the port is busy, e.g. a second client on the same machine, `Net.lan_listening` stays `false` and nothing else happens. Joining by IP still works.

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
  - Each player entry in a snapshot carries `seq`, the last input sequence number the host applied for that player.
  - The client replays its inputs with a higher `seq`.
- **Everything else** (other players, enemies, projectiles, pickups, hazards, summons, boss) comes from **full, quantized snapshots** of the `ViewState` (architecture §3). The host sends them at 15–20 Hz, while the physics tick stays at 60 Hz.
- **Projectiles are included in snapshots.** This replaces the earlier plan of fire events plus client-side projectile simulation. Rationale:
  - **One path:** the renderer draws only a `ViewState` on every machine, so there's no second, client-side projectile simulation that could drift from the host (spread, piercing, homing, wall bounces).
  - **Cost:** a projectile is only 6 bytes (type, int16 position, u8 angle), so 300 projectiles cost about 1.8 KB per snapshot, which fits the budget below.
  - **Hits are still decided only by the host.**
- **No delta compression and no client-side spawn schedules in the MVP.** A full snapshot is self-contained, so a lost packet costs nothing beyond its own frame. The seed still drives every random roll on the host.
- **No full lockstep.** Godot physics isn't deterministic, so the seed only drives schedules and random numbers. The host's state always wins.

### 6.1 Snapshot format (`src/net/snapshot.gd`)
- **Encoding:** `StreamPeerBuffer`, little endian, starting with a version byte (`Snapshot.VERSION`). `Snapshot.decode()` returns `null` for truncated data, malformed data or another version.
- **Layout:** struct-of-arrays (all ids, then all types, then all positions …), so the range coder sees similar bytes together.

| Data | Encoding | Max error |
|---|---|---|
| positions | int16 per axis, rounded, clamped to the int16 range | 0.5 px |
| fractions (enemy hp, hazard life, boss hp and shield) | u8 0..255 | 1/510 |
| angles (projectiles, player aim) | 1 byte, TAU/256 per step; decoded in [-PI, PI) | TAU/512 |
| hazard radius | u16, rounded | 0.5 px |
| ids | int32 | exact |
| player `seq` | u32 | exact |
| player hp and max hp, `time`, `wave_time_left` | float32 | float32 |
| counts | u16 | exact |
| `boss` | presence byte, then `enc`, `hp`, `phase`, `shield` | as above |

- **Per-entity cost:**
  - **enemy:** 11 bytes
  - **projectile:** 6 bytes
  - **pickup or summon:** 5 bytes
  - **hazard:** 8 bytes
  - **player:** 27 bytes, plus 1 per weapon
- **Caps per snapshot:**
  - 300 enemies
  - 400 projectiles
  - 300 pickups
  - 64 hazards
  - 64 summons
  - 8 players
  - 16 weapons per player

  Extra entities beyond a cap are not sent.
- **Budget:** a busy frame (200 enemies, 300 projectiles, 100 pickups, 20 hazards, 6 summons, 4 players and a boss) is **4.8 KB raw** and about **4.6 KB on the wire** (positions barely compress).
  - At 20 Hz that's about **0.75 Mbit/s per client**, so a listen host with 3 clients uploads about 2.2 Mbit/s. At 15 Hz it's 1.7 Mbit/s.
  - Snapshots are larger than the MTU, so ENet fragments them. Losing one fragment drops that snapshot, and the next one replaces it. Godot warns about this once per process.

### 6.2 Client interpolation (`src/net/snapshot_buffer.gd`)
- **Buffer:** `push(vs, recv_time_s)` keeps the last 10 snapshots on a receive-time timeline. Out-of-order snapshots are dropped.
- **Sampling:** `sample(now_s, delay := 0.1)` returns the world at `now - delay`:
  - **enemies:** matched by `e_id`. Positions are lerped when the id is in both snapshots; new ids take the newer position; ids missing from the newer snapshot disappear.
  - **players:** matched by `id`. `pos` and `aim` are lerped; every other field, including `seq`, comes from the newer snapshot.
  - **projectiles, pickups, hazards, summons, boss:** taken from the newer snapshot, since they have no ids.
- **Edge cases:**
  - an empty buffer returns `null`
  - a single snapshot is returned as is
  - before the oldest snapshot, the oldest one is returned
  - past the newest snapshot, positions are extrapolated from the last two snapshots for at most 100 ms
- **Read-only:** returned ViewStates may share arrays with the buffer.

## 7. Session lifecycle

1. **Lobby:**
   - Players join and pick their characters, and the group picks the Organisation and Umfrage level.
   - The host starts the run. A dedicated server starts it automatically (§9).
2. **Handshake:** the client sends a protocol and game version. A mismatch is rejected with a clear message.
3. **Joining mid-run:** not in the MVP. Lobby only.
4. **A client disconnects:** their character is removed and the enemy scaling adjusts at the start of the next wave.
5. **The host disconnects:** the run ends. There's no host migration in the MVP.

### 7.1 Handshake (implemented in `src/autoload/net.gd`)
1. **Hello:** once ENet connects, the client sends `hello(PROTOCOL_VERSION, application/config/version, name)`.
2. **Checks:** the host checks, in this order:
   - **version:** both must match, else `NET_ERR_VERSION`
   - **run in progress:** a run counts as active when `Game.config` is non-empty, else `NET_ERR_RUNNING`
   - **lobby size:** at most 4 players, else `NET_ERR_FULL`
3. **Rejection:** the client receives `reject(reason)`, emits `connection_failed(reason)` and closes. The host drops the peer after 1 s.
   - ENet accepts 2 connections beyond the player limit, so that a client of a full lobby still gets its reason.
4. **Acceptance:** the host adds `{name, char: "stadtbild", ready: false}` to the lobby, sends `welcome` (the client emits `connected`) and resyncs the lobby.
5. **Timeouts:**
   - A client that isn't welcomed within **8 s** gets `connection_failed("NET_ERR_TIMEOUT")`.
   - A pending peer that never says hello is dropped after 8 s.
   - If ENet itself fails to connect, the client gets `NET_ERR_CONNECT`.
6. **Stable RPC ids:** the handshake RPCs are named `_rpc_00_hello`, `_rpc_01_reject` and `_rpc_02_welcome`.
   - Godot numbers RPCs by sorted method name, so these keep the same ids across game versions, and an old client still gets a clean version error.
   - Never rename them or change their arguments.

### 7.2 Lobby
- **Ownership:** the host owns `Net.lobby` (`{peer: {name, char, ready}}`), `Net.org` and `Net.difficulty`, and pushes all three to every client on every change. Each push emits `lobby_changed`.
- **Client changes:** clients call `set_char` and `set_ready`, which become requests to the host. The host validates them: the char must be in `Content.CHAR_ORDER`, the org in `Content.ORG_ORDER`, and the difficulty is clamped to 0..5.
- **Names:** trimmed, `|` replaced, at most 20 characters.
- **A peer leaves:**
  - The host removes it from the lobby, emits `peer_left(peer)` and resyncs.
  - On a dedicated server, if the lobby empties during a run, `Game.back_to_lobby()` is called.
- **Losing the host:** the client gets `disconnected("NET_ERR_LOST")`. ENet peer timeouts are set to a maximum of 10 s.
- **Return to lobby:** `return_to_lobby()` resets every ready flag and makes every peer emit `returned_to_lobby`.

### 7.3 Run traffic and channels
- **RPC placement:** every RPC lives on the `Net` autoload (`/root/Net`, the same path on every peer). `server_relay` is off, so clients only ever talk to the host.
- **Host-local behaviour:**
  - The host's own inputs and requests are applied by `Game` directly; `send_input` and `send_request` do nothing on the host.
  - `broadcast_run_start` also emits `run_start_received` locally.
  - `send_snapshot`, `send_meta` and `send_events` do nothing in solo.
- **Channels:** ENet orders packets per channel, so unreliable snapshots never block reliable traffic.

| ENet channel | Mode | Traffic |
|---|---|---|
| 0 | reliable | handshake, lobby sync, `set_char`, `set_ready` |
| 1 | reliable | run start, meta, events, requests, return to lobby |
| 2 | unreliable_ordered | snapshots (host → clients) |
| 3 | unreliable_ordered | inputs `(seq, dir)` (client → host; `dir` is clamped to length 1) |

## 8. Saves & trust

- **Meta progression is saved locally on each player's machine.** Hosts never store client progress.
- **Unlocks are checked client-side** when a player picks a character, and the host accepts the choice.
- **Trust model:** co-op among friends. The host validates gameplay requests for consistency, but there's **no anti-cheat**.

## 9. Dedicated server

```
godot --headless --path . -- --server [--port=N] [--org=<id>] [--umfrage=0-5] [--name=<text>] [--no-upnp]
```
- **Startup:** with `--server` in the user args or the engine args, `Net` calls `start_dedicated()` one frame after `_ready`. If the port can't be bound, it exits with code 1.
  - `dedicated = true`, and the server has no local player.
  - The server announces itself on the LAN and tries UPnP unless `--no-upnp` is given.
- **Logging:** in headless mode it prints status and lobby lines (`[Net] …`) to stdout.
- **Auto-start:** once the lobby has at least one player and everyone is ready, a 3 s countdown starts, and then `Game.start_run()` is called. The countdown is cancelled when someone un-readies or joins.

## 10. Tests

- **Unit tests:** `tests/godot/test_snapshot.gd`, `test_snapshot_buffer.gd` and `test_net_lobby.gd` (no sockets) run with `godot --headless --path . -s res://tests/godot/run_tests.gd -- <filter>`.
- **Smoke test:** `GODOT=<godot binary> tools/net_smoke.sh` starts a headless host (port 24813, no UPnP) and two headless clients. It passes when:
  - the client with a wrong protocol version is rejected with `NET_ERR_VERSION`
  - the other client completes the handshake and receives at least 5 snapshots and a meta dict

## 11. Open items

- When to build join codes / punch-through.
- Snapshot bandwidth: if hosts' upload turns out too small, add delta compression or interest management (e.g. send projectiles at a lower rate).
- The interpolation timeline uses receive times, so network jitter shows up as slight unevenness. A smoothed clock offset against `ViewState.time` would fix that if it's noticeable.
