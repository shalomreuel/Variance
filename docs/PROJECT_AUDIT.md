# Variant Zero — existing project audit (2026-09-25)

## Baseline

- **Engine:** Godot 4.6 (`config_version=5`, GL Compatibility). `project.godot` launches `start_screen.tscn` (UID `btcmllj5482g3`). No viewport/stretch or input actions configured.
- **Scenes:** `start_screen.tscn`, `lab.tscn`, `code_editor.tscn`. They contain only texture rectangles. None has a script, button, signal, physics body or transition; the original project does not yet have a navigable game loop.
- **Player/movement:** A `TextureRect` named `Maincharacter` in the lab. No movement, collision, animation or spawning logic.
- **UI:** Three existing PNG backdrops, with the start/editor imagery assigned opposite their likely intended roles. No functional UI, HUD, professor or results screen.
- **Autoloads/GameState/API:** None. No networking, genetics data/engine, quest or save system.
- **Assets:** Existing lab environment (`ChatGPT Image Sep 22, 2026, 10_35_30 AM.png`), sci-fi UI frame (`ChatGPT Image Sep 25, 2026, 11_40_17 AM.png`), cinematic lab title art (`ChatGPT Image Sep 25, 2026, 12_13_54 PM.png`), and five sprites. The five sprite files depict a student (`main sprite.png`), professor (`prof sprite.png`), genetics computer (`comp sprite.png`), desk (`desk sprite.png`) and glowing specimen tank (`pod sprite.png`). Preserve the original assets; use derived transparent versions in the world since most originals contain opaque dark background pixels.
- **Shaders/effects:** None.

## Implementation approach

Keep all three scene paths and original art. Make the start scene a real title/continue screen; make `lab.tscn` the explorable world, with a CharacterBody2D, collisions and two Area2D interactions; make `code_editor.tscn` a functional lab overlay. Add a professor overlay, an offline deterministic genetics/learner/quest stack, a single persistent GameState autoload, and one AIManager autoload that speaks only to a provider-agnostic backend. The backend is optional: every science/gameplay path works locally when it is offline.

The dog traits are **explicitly a simplified fictional Mendelian teaching model**, not claims about the true inheritance of canine coat, ears, eyes, etc., which is often polygenic. The engine owns all biological outcomes; AI supplies explanation/wording only.

## Verification environment

The sandbox initially had no `godot` executable; a Godot 4.6 runtime must be obtained for engine-level launch checks. Backend unit tests and GDScript parser checks can run independently. Record any remaining inability to execute the Godot binary rather than asserting unperformed manual tests.
