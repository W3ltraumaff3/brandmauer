# Brandmauer

A German political-satire arena roguelite made with Godot 4.7.2. It plays in single player or self-hosted co-op for 1–4 players.

**Status:** pre-production (specs). Start with [docs/README.md](docs/README.md).

## Development

### Requirements

- [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard build (not .NET)
- Python 3.12 for the research scripts, the quote tests and `tools/gen_sfx.py` (stdlib only)
- To export builds locally: the Godot 4.7.2 export templates (*Editor → Manage Export Templates*)

### Running the game

Open the project in the Godot editor and press F5, or run it from the command line:

```sh
godot --path .
```

### Tests

```sh
tools/run_tests.sh            # imports assets, then runs every tests/godot/test_*.gd
tools/run_tests.sh audio      # only test files whose name contains "audio"
python -m unittest discover -s tests -v   # quote data
```

`tools/run_tests.sh` finds Godot through `$GODOT`, then `godot`/`godot4` on `PATH`, then a few default install locations. To run the test runner directly:

```sh
godot --headless --path . --import
godot --headless --path . -s res://tests/godot/run_tests.gd [-- <filter>]
```

CI (`.github/workflows/ci.yml`) runs the quote checks, the Godot tests and the network smoke test on every PR.

### Dedicated server

The "Linux Server" export is the same game with the `dedicated_server` and `server` feature tags. Run it headless:

```sh
./BrandmauerServer.x86_64 --headless --server
# from a checkout instead:  godot --headless --path . --server
```

Players join by IP and port (UDP, default `24713`; forward this port on your router or VPS firewall).

### Exports and releases

`export_presets.cfg` defines four presets:

| Preset | Output |
|---|---|
| Windows Desktop | `build/windows/Brandmauer.exe` |
| Linux | `build/linux/Brandmauer.x86_64` |
| macOS | `build/macos/Brandmauer.zip` (ad-hoc signed and not notarized, so on first launch you must right-click and choose *Open*) |
| Linux Server | `build/server/BrandmauerServer.x86_64` |

```sh
godot --headless --path . --export-release "Linux" build/linux/Brandmauer.x86_64
```

`.github/workflows/release.yml` builds all four presets. Starting it manually (*Actions → Release → Run workflow*) only uploads the zips as workflow artifacts. Pushing a `v*` tag also publishes them as a GitHub Release.

### Sound effects

All sound effects in `assets/sfx/` are synthesized by `tools/gen_sfx.py`, which is deterministic and uses a fixed seed. After editing it, run `python tools/gen_sfx.py` and then `godot --headless --path . --import`.
