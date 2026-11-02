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
| `wall` (intact segments) | u64 bitmask, 38 bits used (`Snapshot.VERSION` 2 since D-082; version 1 had a u16 with 12 bits) | exact |
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
3. **Joining mid-run:** not in the MVP. Lobby only. The one exception is a **reconnect** with a valid session token (§7.4).
4. **A client disconnects:**
   - **in the lobby, or deliberately** (menu, quit): their entry and character are removed at once.
   - **mid-run, connection lost** (network problem or game crash): their character stays as **away until the run ends**, and they can come back at any time (§7.4). The enemy scaling keeps counting them.
5. **The host disconnects:** the run ends. There's no host migration in the MVP. Clients first retry for up to 60 s (§7.4); a host that quits deliberately tells them, so they go straight to the menu.

### 7.1 Handshake (implemented in `src/autoload/net.gd`)
1. **Hello:** once ENet connects, the client sends `hello(PROTOCOL_VERSION, application/config/version, name)`.
2. **Checks:** the host checks, in this order:
   - **version:** both must match, else `NET_ERR_VERSION`
   - **run in progress:** a run counts as active when `Game.config` is non-empty, else `NET_ERR_RUNNING`
   - **lobby size:** at most 4 players, else `NET_ERR_FULL`
3. **Rejection:** the client receives `reject(reason)`, emits `connection_failed(reason)` and closes. The host drops the peer after 1 s.
   - ENet accepts 2 connections beyond the player limit, so that a client of a full lobby still gets its reason.
4. **Acceptance:** the host adds `{name, char: "stadtbild", ready: false}` to the lobby, sends `session(token, player_id)` and then `welcome` on the same reliable channel (the client emits `connected`), and resyncs the lobby.
   - **Session token:** 16 random bytes (`Crypto.generate_random_bytes`) as 32 hex characters, one per player, kept by the host for the whole session.
   - The client keeps the token, its player id and the host's `ip:port` in memory for reconnects. During a run it also saves them to `user://rejoin.json`, so it can rejoin after a crash (§7.5).
5. **Timeouts:**
   - A client that isn't welcomed within **8 s** gets `connection_failed("NET_ERR_TIMEOUT")`.
   - A pending peer that never says hello is dropped after 8 s.
   - If ENet itself fails to connect, the client gets `NET_ERR_CONNECT`.
6. **Stable RPC ids:** the handshake RPCs are named `_rpc_00_hello`, `_rpc_01_reject` and `_rpc_02_welcome`.
   - Godot numbers RPCs by sorted method name, so these keep the same ids across game versions, and an old client still gets a clean version error.
   - Never rename them or change their arguments. New RPCs (`_rpc_session`, `_rpc_resume`, `_rpc_bye`, `_rpc_host_closed`, …) sort after them.
7. **Protocol version:** `PROTOCOL_VERSION` is **3** since `_rpc_want_run` was added for rejoining after a crash (§7.5). Version 2 added the reconnect RPCs. New RPCs shift the ids of every later RPC.

### 7.2 Lobby
- **Ownership:** the host owns `Net.lobby` (`{player_id: {name, char, ready}}`), `Net.org` and `Net.difficulty`, and pushes all three to every client on every change. Each push emits `lobby_changed`.
- **Client changes:** clients call `set_char` and `set_ready`, which become requests to the host. The host validates them: the char must be in `Content.CHAR_ORDER`, the org in `Content.ORG_ORDER`, and the difficulty is clamped to 0..5.
- **Names:** trimmed, `|` replaced, at most 20 characters.
- **A peer leaves** (in the lobby, after its grace period, or with `bye`):
  - The host removes it from the lobby, forgets its token, emits `peer_left(player_id)` and resyncs.
  - On a dedicated server, if the lobby empties during a run, `Game.back_to_lobby()` is called.
  - Away players still count as being in the lobby. So a dedicated server also ends the run once **nobody has been connected for 5 minutes** (`Net.EMPTY_SERVER_S`), every player being away. Otherwise it would wait forever.
- **Deliberate leave:** `Net.leave()` sends a goodbye and flushes it before closing, so nobody waits for a reconnect that never comes:
  - a client sends `bye`: the host removes it at once, without a grace period.
  - a host or dedicated server sends `host_closed`: clients leave at once with `disconnected("NET_ERR_HOST_CLOSED")`.
  - The old ENet peer stays open for 0.3 s after a goodbye (ENet drops packets that aren't dispatched yet when the disconnect arrives in the same poll). If the goodbye is lost anyway, the normal timeout path applies.
- **Losing the host:** mid-run with a token, the client reconnects (§7.4); otherwise it gets `disconnected("NET_ERR_LOST")`.
- **ENet peer timeouts** (`ENetPacketPeer.set_timeout(32, 5000, 15000)`, both sides): the limit is a factor on the round-trip time; a peer is **never dropped before 5 s** without acknowledgement and **always after 15 s**. Short lags therefore don't disconnect anyone.
- **Return to lobby:** `return_to_lobby()` removes away players (they can only rejoin a running run), resets every ready flag and makes every peer emit `returned_to_lobby`.

### 7.3 Run traffic and channels
- **RPC placement:** every RPC lives on the `Net` autoload (`/root/Net`, the same path on every peer). `server_relay` is off, so clients only ever talk to the host.
- **Host-local behaviour:**
  - The host's own inputs and requests are applied by `Game` directly; `send_input` and `send_request` do nothing on the host.
  - `broadcast_run_start` also emits `run_start_received` locally.
  - `send_snapshot`, `send_meta` and `send_events` do nothing in solo.
- **Channels:** ENet orders packets per channel, so unreliable snapshots never block reliable traffic.

| ENet channel | Mode | Traffic |
|---|---|---|
| 0 | reliable | handshake (`hello`, `reject`, `session`, `welcome`, `resume`), lobby sync, `set_char`, `set_ready`, `bye`, `host_closed` |
| 1 | reliable | run start, meta, events, requests, return to lobby |
| 2 | unreliable_ordered | snapshots (host → clients) |
| 3 | unreliable_ordered | inputs `(seq, dir)` (client → host; `dir` is clamped to length 1) |

### 7.4 Short disconnects and reconnects (implemented in `src/autoload/net.gd`, `game.gd`, `sim.gd`)

**Goal:** a short connection loss mid-run must not throw anyone out. The host computes the game, so a client can't play on alone; it waits and reconnects as soon as possible.

**Player ids vs. peer ids (design):**
- A player's **player id** is the ENet peer id of its **first join**. It never changes, so `Sim`, `Game`, meta, events, the result and `Net.lobby` stay keyed by it.
- A reconnect gets a **new ENet peer id**. Only `Net` knows the mapping (`_peer_of: player_id -> current peer`, `0` while away):
  - incoming RPCs are translated with `player_for_peer(sender)`; a peer that no longer belongs to a player (the dead old connection) maps to `0` and is ignored.
  - outgoing sends go to `peer_for_player(player)`; away players get nothing.
  - `Net.local_player_id()` / `Game.local_id()` return the player id on the client, not `multiplayer.get_unique_id()`.
- Rationale: renaming the player inside `Sim` would mean rewriting every owner reference (projectiles, hazards, summons, votes, intro flags, stats); the mapping keeps `Sim` unaware of the network.

**Host (away until the run ends):**
1. A client's peer disconnects while a run is active (`Game.config` non-empty) and without `bye`: the host keeps its lobby entry, marks it away **until the run ends** and emits `peer_away(player)`.
2. `Game` calls `Sim.set_away(player, true)`: the player gets **state 3 "away"** and the event `["away", player]` goes out (architecture §3, §5). An away player:
   - keeps its character, **frozen** (no movement, weapons or ultimate, requests refused) and **greyed out** in the view.
   - is **invulnerable** and **not targeted** by enemies.
   - **doesn't block** the Späti ready check or the boss intro wait. If everyone present is ready, the next wave starts without them.
   - still counts for enemy scaling and the Koalitionskasse (`num_players`), gets wave income, Späti offers and level-ups.
   - **never causes a game over.** While nobody is alive and at least one player is away (`Sim.waiting_for_away()`, e.g. the only other player is downed, or a dedicated server whose only client dropped), the world waits. If they're removed (deliberate leave, empty dedicated server), the normal game-over check applies.
   - comes back in the state it left in (a downed player is still downed); waves that started in between bring it back alive.
3. When the client comes back (below, or §7.5 after a crash), the host emits `peer_back(player)`, `Game` calls `Sim.set_away(player, false)` (event `["back", player]`) and forces a fresh meta, snapshots resume at once.
4. Away players are removed only when the run ends or returns to the lobby, or by the empty-server rule (§7.2).

**Client (reconnect):**
1. On losing the host mid-run with a token (`server_disconnected` in `CLIENT` mode), `Net` switches to `RECONNECTING` and emits `connection_lost`, instead of `disconnected`.
2. `Game` keeps the run: it keeps rendering the last snapshot (extrapolated for at most 100 ms, then held) and keeps predicting its own movement locally. Inputs and requests aren't sent meanwhile.
3. The HUD shows a small **disconnect indicator** in the top-right corner: an unplugged plug in an orange frame, "Verbindung weg – verbinde neu …" and the seconds left. The Funkloch easter egg is suppressed meanwhile, so the joke and the real problem never look alike.
4. `Net` starts an ENet connection to the stored `ip:port` right away and **every 2 s** (`RETRY_INTERVAL_S`). An attempt that has connected gets up to 8 s for the answer. On connect it sends `resume(protocol, version, token)` instead of `hello`.
5. The host checks `resume`: same version, a run is active, the token belongs to a lobby player. Else it rejects with `NET_ERR_VERSION` / `NET_ERR_SESSION`, and the client gives up at once.
   - This is the only way into a running run: a plain `hello` still gets `NET_ERR_RUNNING`.
   - If the host hasn't noticed the old connection dying yet, it disconnects the old peer itself; that peer's disconnect is then ignored.
   - On success the host maps the new peer to the player and sends `session(token, player)` + `welcome`; the client emits `reconnected`, `Game` clears its snapshot buffer and its unacknowledged predicted inputs, and play continues.
6. After **60 s** (`RECONNECT_S`) without success, or on a rejection, the client leaves and gets `disconnected("NET_ERR_LOST")`: back to the menu with that message. Its character stays away on the host, so it can still rejoin from the menu (§7.5).

**Solo is unaffected:** no socket, so no disconnects, no away state, no timers, no indicator. The host's own player (peer 1) is never away.

**Limitations:**
- No host migration: if the host is gone for good, clients retry for 60 s and then return to the menu.
- Events sent while a client was away (sounds, speech bubbles, toasts) are lost; meta and snapshots are full state, so everything else catches up.
- A run that ends or returns to the lobby drops the away players; their reconnect is then rejected.

### 7.5 Rejoining after a crash (implemented in `src/autoload/net.gd`, `game.gd`, `save.gd`, `src/ui/main_menu.gd`)

**Goal:** a player whose game crashed (or who gave up reconnecting) gets back into the running run from the main menu.

**Client: the rejoin file.**
- When a co-op run starts on a client, `Save` writes `user://rejoin.json`: `{ip, port, token, player, version, saved_at}`. Tests and tools never write it (`Save.persist = false`).
- The file is deleted when the client leaves the run on purpose. That covers:
  - quitting to the menu
  - closing the window (the client says goodbye, so the host removes the player)
  - the run ending (end screen)
  - returning to the lobby
  - the host closing the game
  - a rejected rejoin
- A crash or a lost connection (`NET_ERR_LOST`) keeps it.
- It counts only if `version` matches the running game and it is younger than **6 hours**.

**Main menu.**
- With a valid rejoin file the menu shows **"Zurück ins Spiel"** as the first button, with the host's address as tooltip.
- Pressing it calls `Game.open_rejoin()`: Game mode CLIENT, `Net.rejoin(ip, port, token, player)`. Net enters `RECONNECTING` with the stored session and tries for up to **15 s** (`REJOIN_S`), every 2 s, exactly like §7.4.
- On `welcome` the client emits `reconnected`. `Game` has no run yet, so it sends `want_run` (CH_RUN). The host answers with `run_start(config)` to that peer only and forces a fresh meta. The client starts the run screen, and snapshots and meta take over.
- **On failure** the client is back in the menu with the reason, and the rejoin file is deleted:
  - `NET_ERR_SESSION`: the run is over, or the host doesn't know the token.
  - `NET_ERR_LOST`: no host reachable within 15 s.

**Host.** `want_run` is answered only for a player that is in the lobby and connected, while a run is active.

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

- **Unit tests:** `tests/godot/test_snapshot.gd`, `test_snapshot_buffer.gd`, `test_net_lobby.gd` (no sockets; includes grace period, player/peer mapping, token checks and the client reconnect state machine) and `test_sim_away.gd` (Sim away state) run with `godot --headless --path . -s res://tests/godot/run_tests.gd -- <filter>`.
- **Smoke test:** `GODOT=<godot binary> tools/net_smoke.sh` runs two scenarios. It passes when every process exits 0:
  1. A headless host (port 24813, no UPnP) and two headless clients:
     - the client with a wrong protocol version is rejected with `NET_ERR_VERSION`
     - the other client completes the handshake and receives at least 5 snapshots and a meta dict
  2. **Reconnect** (port 24815, real `Game` + `Sim` run): the client drops its connection mid-run without telling the host and reconnects with its token.
     - `host-run` passes if the player went away (sim state 3, still in the lobby), came back on a new peer id that maps to the same player id (state alive/downed again), and then left with `bye`.
     - `join-reconnect` passes if its run state survived the drop, its player id stayed the same on a new peer id, and it received at least 5 snapshots (own player not away) plus meta after the reconnect.
  3. **Rejoin after a crash** (second `host-run`):
     - `join-crash` joins, saves its session to a temp file after 10 run snapshots and kills its own process (no goodbye).
     - After 16 s (the host has noticed the dead peer), a fresh `rejoin` process calls `Game.open_rejoin()` with that session. It passes once it runs the run again as the same player and received at least 5 snapshots (player not away) plus meta.
     - `host-run` passes as in scenario 2.
- **Unit tests for the rejoin:** `test_rejoin.gd` (saved session: version and age check, kept on a lost connection, dropped on every deliberate exit) and `test_net_lobby.gd` (away until the run ends, empty dedicated server, rejoin state machine).

## 11. Open items

- When to build join codes / punch-through.
- Snapshot bandwidth: if hosts' upload turns out too small, add delta compression or interest management (e.g. send projectiles at a lower rate).
- The interpolation timeline uses receive times, so network jitter shows up as slight unevenness. A smoothed clock offset against `ViewState.time` would fix that if it's noticeable.
