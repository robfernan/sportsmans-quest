# 🌲 Sportsman's Quest: Whispering Pines Reserve

![Sportsman's Quest Banner](media_banner.jpg)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Engine: Godot 4](https://img.shields.io/badge/Engine-Godot%204.x-blue.svg)](https://godotengine.org)
[![Build Size](https://img.shields.io/badge/Data%20Package-240%20KB-orange.svg)](#architecture)
[![Status: Released](https://img.shields.io/badge/Status-Released%20on%20Itch.io-red.svg)](https://mungdaal321.itch.io/sportsman-quest)
[![Releases](https://img.shields.io/github/v/release/robfernan/sportsmans-quest)](https://github.com/robfernan/sportsmans-quest/releases/tag/v1.0.0)

> **An ultra-lean, offline-first 3D stalking hunting simulation & Halloween cryptid hunt.**
> Built as an open-source homage to retro hunting classics and the golden era of *theHunter Classic*.

![In-Game Gameplay Screenshot](media_screenshot.png)

---

## 🎮 Play & Download

- **Itch.io Storefront**: [https://mungdaal321.itch.io/sportsman-quest](https://mungdaal321.itch.io/sportsman-quest)
- **Windows Standalone**: `SportsmansQuest_Windows_ReadyToPlay.zip` (self-contained, no install required).
- **Web (HTML5)**: `SportsmansQuest_Web.zip` (play directly in the browser via WebGL).

---

## ⚡ Core Architecture: Procedural Efficiency

Commercial hunting games (*theHunter: Call of the Wild*, *Way of the Hunter*) require **30 GB to 60 GB** of high-resolution photogrammetry textures, rigged meshes, and baked audio. 

**Sportsman's Quest** takes the opposite design philosophy: **100% procedural generation with zero external textures, zero .gltf files, and zero pre-recorded audio files**.

| Subsystem | Traditional Games | Sportsman's Quest |
| :--- | :--- | :--- |
| **Terrain** | Multi-GB 4K normal/albedo textures | Multi-frequency analytical sine/hash noise shader ([`terrain.gdshader`](src/world/terrain.gdshader)) |
| **Vegetation** | High-poly tree models + LOD meshes | Procedural conifer geometry with wind-vertex sway shaders instanced on GPU via `MultiMesh` |
| **Audio** | Uncompressed .wav / .ogg sound banks | 100% synthetic PCM sound generation in real-time math ([`audio_synth.gd`](src/core/audio_synth.gd)) |
| **Wildlife** | Gigabytes of rigged skinned meshes | Algorithmic hierarchical jointed box/capsule models generated dynamically |
| **Game Data Package** | 30+ GB | **~240 KB game data** (`dist/SportsmansQuest.pck`) |

---

## 🎯 Gameplay Features

### 1. Realistic Stalking & Ballistics
- **Ballistics Curve**: Real-time bullet drop, gravity, and lateral crosswind drift.
- **Rifle Scope Elevation Zeroing**: Toggle zero settings between **100m**, **200m**, and **300m** (`F` key).
- **Roper Revolving Shotgun**: Historic 1866 cylinder shotgun holding 4 rounds with on-the-fly ammo switching between **Birdshot**, **00 Buckshot**, and **Rifled Slugs**.

### 2. Sensory Wildlife Simulation
- **Prey Senses**: Whitetail deer herds track the player's line of sight, noise output (sprint 75m, walk 28m, crouch 9m, prone 2.5m), and downwind scent plume.
- **Wind Detection**: Puff talcum powder (`P` key) to visualize wind vector and current drift.
- **Waterfowl Systems**: Deploy floating mallard decoys (`G` key) and pitch shoreline reed blinds (`B` key).

### 3. Loyal Hunting Companion (Golden Retriever)
- Command wheel (`K` key):
  - **Heel**: Follows close behind without spooking game.
  - **Stay**: Sits and waits at blinds or stands.
  - **Blood Tracking**: Leads you directly to wounded animal harvest locations.
  - **Water Retrieve**: Swims into lake waters to fetch downed waterfowl.

### 4. Walkable 3D Trophy Lodge & Photo Mode
- **Taxidermy Mounts**: Walk inside your rustic cedar cabin to inspect full 3D wall mounts for Whitetail Deer (with dynamic antler racks sized to Boone & Crockett score), Foxes, Ducks, and Cryptid beasts.
- **Ground Photo Poses**: Pose directly on the turf beside fallen game (`Ground Kneel`, `Ground Lounge`, `Victory Thumbs-up`) and admire your framed field photos on the lodge walls.

### 5. 🎃 Halloween Special Event
- **Spectral Ghost Buck**: Mythical 14-point translucent stag leaving ethereal tracks (215+ B&C score).
- **Werewolf Apex Predator**: Aggressive beast stalking the pine timber edge that rushes the player with savage claw strikes (25 damage).
- **Wendigo Horror**: 3-meter tall gaunt demonic entity with deer skull head, decaying ribs, and piercing screeches (35 damage).

---

## ⌨️ Controls Reference

| Key | Action |
| :--- | :--- |
| **WASD** | Walk / Stalk / Paddle Kayak |
| **Shift** | Sprint (Increases noise radius to 75m) |
| **Right Click** | Aim Down Scope / Binoculars |
| **Left Click** | Fire Weapon / Deploy Call |
| **C / Ctrl** | Cycle Stance (Stand $\leftrightarrow$ Crouch $\leftrightarrow$ Prone) |
| **1 – 6** | Quick-Equip: Rifle, Shotgun, Binos, Deer Call, Duck Call, Wind Powder |
| **F** | Adjust Scope Zero (100m $\to$ 200m $\to$ 300m) |
| **M** | Topographic GPS Huntermate Map & Compass |
| **P** | Puff Wind Detection Powder |
| **G / B** | Deploy Duck Decoy / Pitch Reed Blind |
| **K** | Companion Dog Command Wheel |
| **E** | Interact (Board Kayak, Claim Fallen Trophy) |

---

## 🛠️ Building & Exporting

### Prerequisites
- [Godot Engine v4.x (Standard 64-bit)](https://godotengine.org)

### Build Commands
```bash
# 1. Run headless test
godot --headless --path . res://scenes/main.tscn --quit-after 3

# 2. Export Ultra-Lite PCK (< 250 KB)
godot --headless --path . --export-pack "Windows Desktop (Ultra-Lite)" "dist/SportsmansQuest.pck"

# 3. Export Web HTML5 Bundle
godot --headless --path . --export-pack "Web" "dist/web/SportsmansQuest.pck"
```

---

## 📜 Changelog

### v1.2 — Halloween Production Polish & Web Optimization
- **Web Rendering Optimization:** Unified procedural MultiMesh vegetation system down from ~450 draw calls to 13 draw calls; reduced tree colliders to 45 solid trunks near paths for butter-smooth 60+ FPS in all web browsers.
- **Physics & Ground Safety Clamping:** Hardened character ground-height clamping, boundary enforcement within the 600m reserve, and velocity limiting to eliminate falling through terrain or map boundaries.
- **Articulated 3D Trophy Photo Rig:** Articulated two-segment knee and elbow joints for realistic photo poses (Ground Lounge, Ground Kneel, Hero Stand, Thumbs-Up, Gun On Shoulder) with proper turf-aligned elevation.
- **Dead Animal Collision Safe-Disable:** Animal collision shape is immediately disabled upon harvesting/death to eliminate physics depenetration ejection.
- **Localized Wildlife Audio:** Fixed bird audio by strictly localizing waterfowl quacks to within 35 meters, removed aim-breathing noise, and added silent circling Halloween ravens in the sky.
- **Vast Wildlife Population:** Expanded reserve fauna to 32 Whitetail Deer (6 herds + 8 trophy bucks), 14 roaming Red Foxes, 14 lake Mallards, and 25 glowing Jack-O'-Lanterns with flickering candle light.
- **Halloween Cryptid Night Hunt Mode:** Deep midnight sky with blood-violet horizon, moonlight directional lighting, drifting valley fog, and relentless cryptids (Wendigo, Werewolf, Ghost Buck).
- **Web UX Navigation:** Integrated on-screen Fullscreen and Menu buttons directly into the HTML5 canvas overlay and in-game HUD.

---

## 📜 License
Distributed under the **MIT License**. Free and open source for everyone.
