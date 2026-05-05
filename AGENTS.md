# Zax Reimplementation Agent Guide

This repository is the Godot 4.6.2 reimplementation of `Zax: The Alien Hunter`.
The original install and extraction project live in `extract-zax-assets/`, which
is intentionally ignored and must not be treated as committed runtime state.

## Source Of Truth

1. Original files under `extract-zax-assets/zax/`, especially `Zax.exe`,
   `Data.dat`, and `Polish.red`.
2. IDA Pro MCP findings from the loaded `Zax.exe` database.
3. Extraction docs and manifests under `extract-zax-assets/docs/` and
   `extract-zax-assets/extracted/manifests/`.
4. Curated runtime copies under `res://assets/zax/`.

If a copied Godot asset appears wrong, fix or re-audit extraction first, then
recopy the curated asset. Do not hand-edit copied JSON/PNG data to hide an
extraction issue.

## Project Layout

- `assets/zax/` contains the committed curated runtime slice copied from the
  ignored extraction project.
- `src/core/` owns asset and level-loading boundaries.
- `src/level/` owns the current debug viewer and future level-presentation code.
- `scenes/app/app.tscn` is the current main scene.
- `tests/test_runner.gd` is the headless validation entrypoint.

Keep new systems small and original-backed. The first priority is visible,
inspectable parity data before gameplay guesses.

## Validation

Use Godot 4.6.2 from the local PATH unless a repo-local binary is added:

```bash
godot --headless --path . --import --quit
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --scene res://scenes/app/app.tscn --quit-after 2
git diff --check
```

Before recopying or trusting extraction-derived data, run this from the ignored
extraction project root:

```bash
python3 tools/audit_ida_asset_coverage.py
```

Headless Godot may print editor/import socket noise in this environment. Treat
that as non-blocking only when the command exits with status 0 and tests pass.

## Documentation Lookup

Use `npx ctx7@latest` for current framework/library/tool documentation when a
task asks about Godot APIs, CLI behavior, setup, migration, or another external
library. Do not use it for business-logic debugging or refactoring that can be
answered from the repo.
