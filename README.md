# Sportsman's Quest

**A procedural 3D stalking sim on Whispering Pines: stay downwind, stay quiet, and walk the harvest back to the lodge.**

By [Robert Fernandez](https://robertfernandez.dev) ([robfernan](https://github.com/robfernan)). Godot 4.7. Offline. One playable reserve.

![Key art: a hunter and retriever on a moonlit shore, jack-o'-lanterns in the foreground, a stag and a tall figure among the pines](media_banner.jpg)

![In-engine photo mode on the lakeshore. The title bar reads Sportsman's Quest (DEBUG). Hunter and dog are block-built meshes on a noise terrain.](media_screenshot.png)

The wide image is key art. The second image is a capture from the Godot scene.

## Play

The published build is [v1.0.0](https://github.com/robfernan/sportsmans-quest/releases/tag/v1.0.0) (28 Oct 2026). The same game is listed on [itch.io](https://mungdaal321.itch.io/sportsman-quest) as "Sportsman Quest" by MungDaal321.

**Windows.** Download `SportsmansQuest_Windows_ReadyToPlay.zip` (91,742,442 bytes). It contains `SportsmansQuest.exe` (180,858,888 bytes) and `SportsmansQuest.pck` (4,204,144 bytes). Unzip and run `SportsmansQuest.exe`.

**Browser.** Download `SportsmansQuest_Web.zip` (18,599,295 bytes). Unzip it and serve the folder. `index.html` loads `godot.js`, `godot.wasm`, and `godot.pck` from that directory.

```bash
unzip SportsmansQuest_Web.zip -d sportsmans-quest-web
cd sportsmans-quest-web
python -m http.server 8080
```

Open `http://localhost:8080`. The pack inside both release zips is a Godot **4.2.2** `GDPC` file. This repository targets Godot **4.7**.

**From source.** Install [Godot 4.7](https://godotengine.org/download/) (the pack in `dist/` was exported with 4.7.2) and run:

```bash
godot --path .
```

The main scene is `scenes/main_menu.tscn`.

| Menu entry | What it does |
| --- | --- |
| Day Hunt Expedition | Loads `scenes/main.tscn` at dawn (06:00). |
| Night Hunt | Same scene, clock set to 10:30 PM, with two extra cryptids. |
| Trophy Lodge | Loads `scenes/trophy_lodge.tscn`. |
| Reserve, Settings | Rewrite the subtitle line. |
| Quit | Closes the game. |

`dist/SportsmansQuest_Compressed.exe` (70,573,064 bytes, Windows PE32+ x86-64) sits next to `dist/SportsmansQuest.pck`. `dist/launch_game.ps1` starts `SportsmansQuest.exe`, and `.gitignore` excludes that filename. Use the release zip or the Godot editor for a known-good launch.

The Windows export preset still records product version `0.2.0`. The git tag is `v1.0.0`.

## On the reserve

Whispering Pines is a 600 m noise terrain and a lake (`Terrain.SIZE` in `src/world/terrain.gd`). Pines, animals, and gunshots are built in code. A search of this tree finds no `.gltf`, `.glb`, `.ogg`, `.wav`, or `.mp3` files. The only raster images are the two pictures above.

You hunt in first person. Deer, foxes, and ducks react to scent on the wind, to footstep noise, and to line of sight. Noise radii on the hunter are sprint 75 m, walk 28 m, crouch 9 m, and prone 2.5 m. Rifle shots go through `Ballistics.simulate_shot`: drag, drop, crosswind, and a zero of 100 m, 200 m, or 300 m. The Roper shotgun is a 4-round cylinder. `T` cycles birdshot, 00 buck, and rifled slug. `R` reloads.

`G` places a floating mallard decoy. `B` pitches a reed blind. `E` boards the kayak, climbs a stand, and harvests a downed animal. Hold `Q` or `Tab` for a gear wheel with the rifle, shotgun, binoculars, deer call, and duck call. Wind powder is `6` or `P`, then left click.

`K` switches the retriever between heel and stay. Blood tracking and a water retrieve are implemented on `RetrieverDog`. `hunter_controller.gd` never calls `order_fetch`.

A harvest opens a third-person photo pose. Trophies are written to `user://sportsmans_quest_save.json`.

Spawn lists in `src/world/game_world.gd` place 32 whitetail (six herds of four, plus eight solitary bucks), 14 red foxes, 14 mallards, and 25 jack-o'-lanterns. A ghost buck, a werewolf, and a wendigo are present on day and night hunts. Night Hunt adds a second ghost buck and a second werewolf.

## Controls

| Input | Action |
| --- | --- |
| `W` `A` `S` `D` | Walk. In the kayak, `W` / `S` paddle and `A` / `D` steer. |
| `Shift` | Sprint |
| `C` | Crouch from stand or prone. Stand if already crouched. |
| `Z` | Prone from stand or crouch. Stand if already prone. |
| `Space` | Jump while standing on the ground |
| Mouse | Look |
| Right click | Aim |
| Left click | Fire, call, or puff powder, whichever is in hand |
| `1`–`5` | Rifle, shotgun, binoculars, deer call, duck call |
| `6` or `P` | Equip wind powder |
| `T` / `R` | Cycle shotgun shell / reload |
| `F` | Rifle zero: 100 m, then 200 m, then 300 m |
| `M` | Huntermate map |
| `G` / `B` | Duck decoy / reed blind |
| `K` | Dog: heel or stay |
| `Q` or `Tab` (hold) | Gear wheel |
| `E` | Interact |
| `Esc` | Pause |
| Backtick or `F10` | Return to the main menu |

## Build

Preset names are in `export_presets.cfg`. Godot 4.7 export templates have to be installed.

```bash
godot --headless --path . --export-pack "Windows Desktop (Ultra-Lite)" dist/SportsmansQuest.pck

godot --headless --path . --export-release "Windows Desktop (Ultra-Lite)" dist/SportsmansQuest.exe

godot --headless --path . res://scenes/main.tscn --quit-after 3
```

The last line is a short smoke run of the reserve scene. The Web preset is named `Web` and writes `dist/web/index.html`. Its `custom_template/release` value points at `C:\Users\User\AppData\Roaming\Godot\export_templates\4.7.2.stable\...` on the author's PC. Point that field at your own web export template before a web export.

`tools/build_web.py` and `tools/package_windows.py` hardcode that same project path. The v1.0.0 web zip is a stock Godot web export (`index.html`, `godot.js`, `godot.wasm`, `godot.pck`). The Windows zip is `SportsmansQuest.exe` plus `SportsmansQuest.pck`.

## Size

These are file sizes, counted from this tree and from the v1.0.0 release archives.

| What | Bytes |
| --- | ---: |
| Every `.gd`, `.gdshader`, `.tscn`, and `project.godot` file (57 files) | 289,695 |
| `dist/SportsmansQuest.pck` (Godot 4.7.2 pack in the repo) | 1,826,512 |
| `dist/SportsmansQuest_Compressed.exe` | 70,573,064 |
| `media_banner.jpg` / `media_screenshot.png` | 894,679 / 776,124 |
| v1.0.0 `SportsmansQuest_Windows_ReadyToPlay.zip` | 91,742,442 |
| v1.0.0 `SportsmansQuest.exe` inside that zip | 180,858,888 |
| v1.0.0 `SportsmansQuest.pck` inside that zip (Godot 4.2.2) | 4,204,144 |
| v1.0.0 `SportsmansQuest_Web.zip` | 18,599,295 |
| `godot.wasm` inside the web zip | 39,514,754 |

The 289,695 byte figure is the sum of those 57 source files, skipping `.git`. That source total is under 1 MB. Runnable builds are the pack, the executables, and the release zips in the rows under it.

Pack versions are the major, minor, and patch integers in the `GDPC` header (format version 4, then `4, 7, 2` for the repo pack and `4, 2, 2` for the release pack). The repo pack's path table includes `res://media_banner.jpg` and `res://media_screenshot.png` plus compiled scripts. Release byte counts are the zip central directory (`unzip -l` on the v1.0.0 assets).

## Star

If you want this reserve to keep growing, star [robfernan/sportsmans-quest](https://github.com/robfernan/sportsmans-quest).

## License

`export_presets.cfg` and `SPORTSMANS_QUEST_OUTLINE.md` name the MIT License. This repository has no `LICENSE` file.
