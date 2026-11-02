# Spec: Code Architecture

**Status:** Approved · **Last updated:** 2026-11-01

Godot 4.7.2, GDScript only. All gameplay is computed in a **pure-logic simulation** (`Sim`, no nodes, no physics engine), so it can be tested headless and runs identically in solo, listen-server and dedicated-server modes ([networking spec](networking.md)).

## 1. Folder layout & ownership

| Path | Content |
|---|---|
| `project.godot`, `scenes/main.tscn`, `src/main.gd` | entry point; main scene switches screens |
| `src/autoload/game.gd` (`Game`) | run flow, mode (solo/host/client/server), run controller (host stepping, client prediction), request routing |
| `src/autoload/save.gd` (`Save`) | local meta progression and options (`user://brandmauer_save.json`) |
| `src/autoload/loc.gd` (`Loc`) | loads every `i18n/*.csv` into Godot's `TranslationServer` at startup |
| `src/autoload/audio.gd` (`Audio`) | music playlists and SFX playback |
| `src/autoload/net.gd` (`Net`) | ENet transport, handshake, lobby, UPnP, LAN discovery, RPCs |
| `src/data/content.gd` (`Content`) | all game content as data: stats, characters, weapons, items, enemies, encounters, organisations, difficulty, Koalitionsvertrag |
| `src/data/quotes.gd` (`Quotes`) | loads `research/zitate_de.json` plus `research/auswahl.json` (the curated selection) |
| `src/sim/sim.gd` (`Sim`) | the simulation |
| `src/sim/arena.gd` (`Arena`) | arena geometry (sheet, four Brandmauer walls, inner arena), wall maths (segments, line of sight, staging walk) and the `Arena.WALL` tunables (GDD §5a); pure static, shared by sim, view, HUD and tools |
| `src/sim/view_state.gd` (`ViewState`) | render and snapshot contract (§3) |
| `src/net/snapshot.gd` (`Snapshot`) | `ViewState` ⇄ bytes |
| `src/net/snapshot_buffer.gd` (`SnapshotBuffer`) | client interpolation buffer |
| `src/view/*` | world renderer (procedural doodle drawing), HUD, effects |
| `src/ui/*` | menus, lobby, Späti, end screen, Album, achievements, options, credits |
| `i18n/*.csv` | translations, one CSV per module (`content.csv`, `ui.csv`, `hud.csv`). Format: `keys,de` |
| `assets/` | fonts, music, sfx (licensed per the [asset spec](asset-licensing.md)) |
| `tests/godot/` | headless GDScript tests (custom runner) |
| `tools/` | helper scripts (SFX generator, net test runner) |

## 2. Content is data
- **Every content entry has a string `id`.** The stable index into the ordered lists in `Content` (e.g. `Content.ENEMY_ORDER`) is the network type id.
- **Player-facing names are translation keys:**
  - `<KIND>_<ID>_NAME` and `<KIND>_<ID>_DESC` (e.g. `WEAPON_DOENER_NAME`, `CHAR_OMA_DESC`)
  - `STAT_<ID>`, `ENEMY_<ID>_NAME`, `ENC_<ID>_NAME`
  - `ORG_<ID>_NAME` / `_DESC`, `VERTRAG_<ID>_NAME` / `_DESC`, `ACH_<ID>_NAME` / `_DESC`, `DIFF_<N>`
- **Never hard-code German text in code.** Always use `tr("KEY")`.

## 3. ViewState (render and snapshot contract)
`ViewState` holds everything needed to **draw** one frame. The host builds it from the `Sim`; clients decode it from snapshots and interpolate it. **The renderer only ever reads a `ViewState`.**

| Field | Type | Meaning |
|---|---|---|
| `time` | float | sim time (s) |
| `phase` | int | `Sim.Phase` (WAVE=0, SHOP=1, OVER=2) |
| `wave` | int | current wave 1..20 |
| `wave_time_left` | float | seconds left; `-1` in the boss wave |
| `stage` | int | Zusammenhalt stage 0..4 |
| `wall` | int | bitmask of intact wall segments (bit i = segment i intact, `Arena.WALL_SEGMENTS` = 38 segments, clockwise from the top-left: 0–11 top, 12–18 right, 19–30 bottom, 31–37 left; GDD §5a). Geometry and wall tunables live in `Arena` (`src/sim/arena.gd`), shared by sim and view |
| `players` | Array[Dictionary] | `{id:int, char:int, pos:Vector2, hp:float, max_hp:float, state:int (0 alive, 1 downed, 2 gone, 3 away: connection lost, frozen, invulnerable, untargeted; networking.md §7.4), aim:float, flags:int, followers:int, weapons:PackedByteArray, seq:int (last input seq the host applied for this player, for client reconciliation)}`. Player flags: 1 reversed controls, 2 stunned, 4 standing still (Klimakleber), 8 invulnerable, 16 reviving someone, 32 ultimate running, 64 only left/right reversed, 128 only up/down reversed (Teilwende, D-108; with 1 set) |
| `e_id` | PackedInt32Array | enemy ids |
| `e_type` | PackedByteArray | index into `Content.ENEMY_ORDER` |
| `e_pos` | PackedVector2Array | |
| `e_hp` | PackedFloat32Array | 0..1 |
| `e_flags` | PackedByteArray | 1 elite/boss, 2 poisoned (also Soli-Sticker), 4 slowed/rooted, 8 winding up/charging, 16 parked/voting, 32 shielded/armored, 64 buffed, 128 hit flash |
| `e_flags2` | PackedByteArray | status effects of GDD §11 (D-092, D-093): 1 In Bearbeitung, 2 Rolle rückwärts, bits 4–16 (`(f >> 2) & 7`) Aktenkundig stacks 0–5, 32 Soli-Sticker, 64 Standfest, 128 Pressekonferenz (boss rules, D-108). The status bits are never set on status-immune enemies |
| `p_type` | PackedByteArray | index into `Content.PROJ_ORDER` |
| `p_pos` | PackedVector2Array | |
| `p_ang` | PackedFloat32Array | radians |
| `k_type`, `k_pos` | PackedByteArray, PackedVector2Array | pickups, index into `Content.PICKUP_ORDER` |
| `h_type`, `h_pos`, `h_rad`, `h_life`, `h_ang` | PackedByteArray, PackedVector2Array, PackedFloat32Array, PackedFloat32Array, PackedFloat32Array | hazards and zones, index into `Content.HAZARD_ORDER`; life is 0..1 remaining; `h_ang` is the direction of a cone (Kahlschlag), 0 for round hazards (D-108). A Menschenkette is 5 consecutive `kette` hazards along the chain, from its owner to its other end; the host moves them every tick and leaves them out while the chain is torn |
| `s_type`, `s_pos`, `s_hp` | PackedByteArray, PackedVector2Array, PackedFloat32Array | summons, index into `Content.SUMMON_ORDER`; `s_hp` 0..1 is the HP of summons that can be hurt (Pappkamerad), 1 for all others. A Menschenkette's lamppost (`laterne`) is only sent while the chain hangs on it |
| `boss` | Dictionary | `{}` or `{enc:int (index into Content.ENCOUNTER_ORDER), hp:float 0..1, phase:int, shield:float 0..1, cast:int (0 none, else 1 + index into Content.BOSS_CASTS), cast_t:float 0..1 progress}` (D-108) |

## 4. Meta state (slow state, Dictionary)
`Sim.build_meta()` returns the per-run slow state. The host sends it reliably whenever it changes (at most 10 Hz), and **all UI reads `Game.meta`**, both on the host and on clients.

```
{
  "wave": int, "phase": int, "org": String, "difficulty": int, "blackrock": bool,
  "kasse": int, "wall_holes": int, "repair_price": int,
  "streik": {"available": bool, "active": float},
  "vertrag": {"options": [String], "votes": {peer_id: int}, "active": String, "waves_left": int},
  "encounter": String,                       # "" or encounter id of this wave
  "team": {"level": int, "xp": float, "need": float, "stage": int},
  "num_players": int,
  "players": { peer_id(int): {
      "name": String, "char": String, "pfand": int, "alive": bool,
      "away": bool,                          # state 3: connection lost, grace period running
      "stats": {stat_id: float},             # final computed stats
      "weapons": [{"id": String, "tier": int}], "max_weapons": int,
      "items": [String],
      "offers": [{"kind": "weapon"|"item", "id": String, "tier": int, "price": int, "sold": bool}],
      "reroll_price": int, "free_rerolls": int, "spend_left": int (-1 = unlimited),
      "levelups": int, "levelup_options": [{"stat": String, "amount": float}], "levelup_reroll_price": int,
      "ready": bool, "paid_in": int, "taken_out": int, "kills": int, "damage": int
  }},
  "result": {}                              # filled when phase == OVER, see §6
}
```

## 5. Requests and events
**Requests** (client → host, reliable): `Game.request(action, arg)`. On the host it's applied directly. On a client it goes through `Net`. Actions:

| Action | Argument |
|---|---|
| `buy` | offer index |
| `reroll` | — |
| `sell` | weapon index |
| `levelup` | option index |
| `levelup_reroll` | — (new level-up options; free reroll first, else `levelup_reroll_price`) |
| `ready` | bool |
| `kasse_in` | — |
| `kasse_out` | — |
| `vote` | option index |
| `repair_wall` | — |
| `streik` | — |

**Events** (host → all, reliable, batched per frame) are arrays `[name, ...]`. The view and audio react to them:

| Event | Payload |
|---|---|
| `sfx` | `[id:String, pos:Vector2]` |
| `dmg` | `[pos, amount:int, crit:bool, to_player:bool]` |
| `kill` | `[pos, enemy_type:int]` |
| `say` | `[pos, text_key:String, quote_id:String]` (exactly one of key/quote is non-empty) |
| `card` | `[encounter_id:String]` |
| `wave_start` | `[wave]` |
| `wave_end` | `[wave]` |
| `stage` | `[stage]` |
| `levelup` | `[team_level]` |
| `down` | `[peer]` |
| `revive` | `[peer]` |
| `away` | `[peer]` (a co-op player lost its connection; the HUD shows a toast, the team panel "weg") |
| `back` | `[peer]` (an away player reconnected) |
| `exit` | `[encounter_id, pos]` (boss exit animation) |
| `wende` | `[duration, axis]` (axis 0 both, 1 left/right, 2 up/down; D-112) |
| `boss_phase` | `[encounter_id, phase]` (phase change: Pressekonferenz banner, D-106) |
| `interrupt` | `[pos, cast_id]` (a stun broke a boss cast: "UNTERBROCHEN", D-107) |
| `streik` | `[duration]` |
| `ach` | `[peer, achievement_id]` |
| `over` | `[won:bool]` |
| `swing` | `[pos, angle, range, arc_deg, weapon_id:String]` (melee/cone attack arc, for drawing) |
| `pulse` | `[pos, radius, kind:String]` (one-shot burst of a v0.3 weapon, drawn on Fx's own-effects layer: `lauti` ska pulse, `sani` heal and shove, `konfetti` Pappkamerad falling over, `offengelegt` Lobbyregister burst) |
| `deny` | `[peer, reason_key:String]` (a request was refused, e.g. `DENY_NO_PFAND`) |

## 6. Result (`meta.result`)
```
{won: bool, wave: int, time: float, difficulty: int, encounters_beaten: [String], wall_intact: bool,
 players: {peer: {char, kills, damage, paid_in, taken_out, steuermoral: float, bought_weapons: int, achievements: [String]}},
 quotes: [String]}        # quote ids that unlock in the Album
```
Each machine updates **its own** save from the `result` entry for its own peer id.

## 7. Modes
| Mode | Behaviour |
|---|---|
| `SOLO` | `OfflineMultiplayerPeer`; the local machine runs the `Sim` with one player (peer 1) |
| `HOST` | ENet server; runs the `Sim`, with the local player as peer 1 |
| `SERVER` | dedicated (`--server` on the command line, headless); runs the `Sim` with no local player and starts a run when all lobby players are ready |
| `CLIENT` | sends input and requests; renders interpolated snapshots and predicts its own movement |

## 8. Module interfaces (autoloads)

### `Net` (src/autoload/net.gd)
Peer ids in signals, `lobby`, meta and the `Sim` are **player ids**: the ENet peer id of a player's first join. After a reconnect only `Net` maps it to the new ENet peer (networking.md §7.4).
```
const PORT := 24713                 # game port (UDP); LAN discovery uses PORT + 1
const PROTOCOL_VERSION := 5         # networking.md §7.1 (5: snapshot v4, D-108)
const GRACE_S := 60.0               # host: away players are kept this long
const RECONNECT_S := 60.0 / RETRY_INTERVAL_S := 2.0   # client reconnect budget / interval
signal lobby_changed                # lobby dict, org or difficulty changed
signal connected                    # client: handshake accepted
signal connection_failed(reason: String)
signal disconnected(reason: String) # we lost the server for good, or it kicked us
signal connection_lost              # client: lost the host mid-run, reconnecting
signal reconnected                  # client: back in the run
signal peer_left(peer: int)         # host: a client left (for good)
signal peer_away(peer: int)         # host: a client's connection dropped mid-run (grace period)
signal peer_back(peer: int)         # host: an away client reconnected with its token
signal lan_games_changed            # discovered LAN games changed
signal run_start_received(config: Dictionary)
signal snapshot_received(bytes: PackedByteArray)
signal meta_received(meta: Dictionary)
signal events_received(events: Array)
signal input_received(peer: int, seq: int, dir: Vector2)
signal request_received(peer: int, action: String, arg)

var lobby := {}        # player_id -> {"name": String, "char": String, "ready": bool}
var org := "gewerkschaft"
var difficulty := 0
var dedicated := false
var lan_games := []    # [{"name", "ip", "port", "players"}]
var upnp_status := ""  # "" | "ok" | "failed: ..."

func start_solo(player_name: String) -> void
func host(player_name: String, port := PORT, use_upnp := true) -> Error
func start_dedicated(port := PORT) -> Error
func join(ip: String, port: int, player_name: String) -> void
func leave() -> void                # says bye/host_closed, closes the peer, removes UPnP mapping, clears the lobby
func is_host() -> bool              # true for solo, host and dedicated
func is_reconnecting() -> bool      # client: lost the host mid-run, retrying (HUD indicator)
func reconnect_time_left() -> float
func local_player_id() -> int       # our player id (stays the same across reconnects)
func player_for_peer(peer: int) -> int    # host: ENet peer -> player id (0 = none)
func peer_for_player(player: int) -> int  # host: player id -> current ENet peer (0 = away)
func is_away(player: int) -> bool         # host: grace period running
func set_char(char_id: String) -> void   # local player
func set_ready(ready: bool) -> void
func set_org(org_id: String) -> void     # host only
func set_difficulty(level: int) -> void  # host only
func start_lan_discovery() -> void / stop_lan_discovery() -> void
func broadcast_run_start(config: Dictionary) -> void  # host: to everyone, incl. a local run_start_received emit
func send_snapshot(bytes: PackedByteArray) -> void    # host -> clients, unreliable_ordered
func send_meta(meta: Dictionary) -> void              # host -> clients, reliable
func send_events(events: Array) -> void               # host -> clients, reliable
func send_input(seq: int, dir: Vector2) -> void       # client -> host, unreliable_ordered
func send_request(action: String, arg) -> void        # client -> host, reliable
func return_to_lobby() -> void                        # host: everyone back to the lobby, ready flags reset
signal returned_to_lobby
```

### `Game` (src/autoload/game.gd)
```
enum Mode { NONE, SOLO, HOST, CLIENT, SERVER }
signal screen_requested(screen: String)   # "menu" | "lobby" | "run" | "end"
signal meta_changed
signal events(events: Array)             # every event batch (host and clients)
signal run_started
signal run_finished(result: Dictionary)
signal message(text_key: String)         # e.g. error toasts
var mode: Mode
var meta := {}           # architecture §4
var view: ViewState      # current frame for rendering (interpolated on clients)
var config := {}         # config of the current run
var blackrock := false   # menu easter egg (set by the menu when "BLACKROCK" is typed)
func local_id() -> int                   # our player id (Net.local_player_id(); 1 on the host and in solo)
func local_meta() -> Dictionary          # meta.players[local_id()] or {}
func open_solo() / open_host(name, use_upnp) / open_join(ip, port, name)  # -> lobby screen
func start_run() -> void                 # host only: builds the config from Net.lobby and broadcasts it
func request(action: String, arg = null) -> void
func back_to_lobby() -> void             # host: after the end screen
func quit_to_menu() -> void
func is_paused() -> bool / set_paused(p: bool)   # pause is solo only
```

### `Save` (src/autoload/save.gd)
```
var data := {}  # unlocked_chars, achievements, album, max_umfrage, stats, options
func is_char_unlocked(id) -> bool; func has_achievement(id) -> bool; func album_has(quote_id) -> bool
func apply_result(result: Dictionary, my_peer: int) -> Dictionary  # returns {"new_achievements": [], "new_quotes": [], "new_chars": []}
func option(key, default); func set_option(key, value); func save()
```

### `Audio` (src/autoload/audio.gd)
```
func play_music(category: String)   # "menu" | "gameplay" | "spaeti" | "boss"; cycles through the playlist
func play_sfx(id: String, pos := Vector2.INF)   # positional only if pos != INF
func set_volumes(music: float, sfx: float)       # 0..1, read from Save options on startup
```
SFX ids: `hit`, `crit`, `kill`, `shoot`, `melee`, `pickup`, `levelup`, `buy`, `hurt`, `down`, `revive`, `wave_start`, `wave_end`, `boss_intro`, `wende`, `streik`, `vote`, `explosion`, `ui_click`, `error`.

### Quotes (src/data/quotes.gd, static)
```
static func get_quote(id) -> Dictionary        # an entry from zitate_de.json
static func ids_for(use: String) -> Array      # e.g. "boss_karte:sauerlaender", "ladebildschirm", "sprechblase:lobbyist"
static func album_ids() -> Array               # all curated ids (research/auswahl.json)
static func random_for(use: String, rng = null) -> String
static func source_label(q) -> String          # "Friedrich Merz, 01.07.2025"
```

## 9. Ultimates (contract)

- **Each character has one ultimate** (`Content.CHARACTERS[id]["ult"]`, data in `Content.ULTS`). It can be used **once per wave** with the `ultimate` input action (Space, gamepad X), via the request `ultimate`.
- **Meta:** `players[pid]["ult"]` (id) and `players[pid]["ult_ready"]` (bool). The root has `"effects": {"tarifrunde": seconds_left, "antrag_gestellt": seconds_left}`; team or global effects only appear while active.
- **Event:** `["ult", peer, ult_id, pos]` when an ultimate fires.
- **ViewState:**
  - Player flag `32` (`PF_ULT`) is set while a personal ultimate effect runs. That covers the Urlaubsantrag sun lounger and Critical Mass (dash and boost).
  - The new summon type `genosse` (Schwarzer Block, black-clad comrades) uses `s_type`/`s_pos`.
  - The Straßenblockade is drawn with ordinary `kleber` hazards.
  - Stunned enemies carry `EF_SLOWED`. Enemies under "Fragen Sie mal uns" carry `EF_BUFFED` (red aura = vulnerable).
- **Texts:** `ULT_<ID>_NAME` and `ULT_<ID>_DESC` in `i18n/content.csv`.

## 10. Run statistics (contract)

`meta.players[pid]["run_stats"]` holds these fields:

| Field | Type | Meaning |
|---|---|---|
| `damage` | Array | `{key, kind, id, tier, sold, total, wave}`, sorted by `total`. `kind` is `"weapon"` (`id` = weapon id, `tier`, `sold` if sold since), `"ram"` (Lastenrad contact), `"ult"` (ultimate) or `"other"`. `total` counts the whole run, `wave` the current or last wave. Damage counts what actually landed (no overkill). Damage over time goes to whoever caused it (D-088): poison ticks to the player and weapon that applied the poison, zone damage (Kleber, Straßenkreide, Brandmauer-Ziegel, Straßenblockade) to the zone's owner and weapon; a zone never takes over a running poison |
| `lifesteal` | int | HP healed through Umverteilung (lifesteal); no overheal |
| `regen` | int | HP healed through Krankenschein (regen); no overheal |
| `sani` | int | HP this player's Demo-Sanis healed (on anyone, GDD §11); no overheal |
| `dmg_taken` | int | damage taken |
| `dmg_blocked` | int | damage absorbed by Kündigungsschutz (armor) |
| `dodges`, `crits`, `kills` | int | counts |
| `pfand_collected` | int | Pfand picked up |
| `pfand_income` | int | Pfand earned at wave end (Nebenjob etc.) |
| `pfand_spent` | int | Pfand spent in the Späti |
| `ults` | int | ultimates used |

## 11. Shop additions (contract)

| Request | Argument | Effect |
|---|---|---|
| `combine` | weapon index | merges that weapon with another of the same id and tier into tier + 1 (max IV) |
| `discard_item` | `{"id", "count"}` (`count` -1 = all) | throws items away, no refund |
| `vote` | `-1` | abstain |
| `ready` | — | refused with `DENY_VOTE_FIRST` while a Koalitionsvertrag vote is open and the player hasn't voted or abstained |

- **Buying a weapon** whose twin (same id and tier < IV) is already owned combines it automatically, even when all slots are full.
- **Event:** `["combine", peer, weapon_id, new_tier]`.
- **Offers** carry `rarity` (items: 1 green, 2 blue, 3 purple, 4 red; colors in `Content.RARITY_COLORS`, names `RARITY_1..4`).
- **`run_stats.damage` rows** carry `merged` (the weapon was combined into a higher tier).
- **Speech bubbles during waves** only carry invented lines and status text, never real quotes. Their opacity is the Save option `bubble_opacity` (0..1, 0 = hidden).
- **Eigene Effekte** (GDD §19a) is the Save option `own_fx_opacity` (0.2..1, default 1). `WorldView` and `Fx` re-read it every frame and multiply it into the alpha of everything the players' side draws except the character bodies. View-only: no snapshot or protocol change. Projectiles count as the players' unless their type is in `WorldView.ENEMY_PROJ`; hazards are the players' if they are in `WorldView.OWN_HAZARDS`. Explosions stay opaque because the snapshot carries no hazard owner.
- **Window mode** is the Save option `window_mode`: `"fullscreen"`, `"maximized"` or `"windowed"`.
