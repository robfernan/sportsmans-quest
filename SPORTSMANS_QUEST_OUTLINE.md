# Sportsman's Quest: Master Project Outline & Asset Plan
**Game Title:** Sportsman's Quest  
**Genre:** Tactical First-Person Open-World Hunting & Waterfowl Simulation  
**License:** 100% Free & Open Source (FOSS - MIT License)  
**Target Engine:** Godot 4 (Compatibility / Mobile / 4K Scalable)

---

## 1. Vision & Core Philosophy

*Sportsman's Quest* is built to fill the void left by modern hunting games:
1. **Content Depth of theHunter Classic:** True animal patience, acute senses (downwind scent cones, sound decay, visual silhouettes), and authentic trophy measurements.
2. **Waterfowl & Watercraft of Bult:** Kayaks, marsh navigation, duck blinds, decoy spreads, and retriever dogs.
3. **Ballistics & Ethics of Way of the Hunter:** Kinetic energy penetration, organ cavitation, and no arcade bullet sponges.
4. **Companion System of Hunting Simulator 2:** A faithful dog that heels, points birds in brush, tracks blood trails, and swims into water to fetch harvested ducks.
5. **100% Fully Offline & Lightweight:** Instant loads, no accounts, runs on integrated laptop graphics while scaling up to crisp 4K.

---

## 2. Free 3D Assets Sourcing Guide (CC0 Public Domain)

All recommended assets below are **100% Free / Public Domain (CC0)**, meaning they can be legally used, modified, and redistributed in your open-source game without copyright issues or royalties:

### 2.1 Animals & Wildlife
- **Quaternius "Ultimate Animated Animals":**
  - Includes: Whitetail Stag, Doe, Fawn, Mallard Duck, Goose, Black Bear, Wolf, Red Fox, Wild Boar, Rabbit.
  - Fully rigged & animated: *Idle, Walk, Trot, Sprint/Flee, Alert/Look, Death/Collapse*.
  - License: CC0 (Public Domain).
  - Source: [quaternius.com](https://quaternius.com) / Poly Pizza.

### 2.2 Vegetation, Trees & Marshlands
- **Quaternius "Ultimate Nature Pack" & Kenney "Nature Kit":**
  - Includes: Pine trees (spruce/fir), birch trees, deadfall logs, river rocks, marsh reeds, cattails, lily pads.
  - Formats: `.gltf` / `.glb` (native drag-and-drop into Godot 4).
  - License: CC0.
  - Source: [kenney.nl](https://kenney.nl) & [poly.pizza](https://poly.pizza).

### 2.3 Firearms, Kayaks & Equipment
- **Kenney "Survival Kit" & "Weapons Kit":**
  - Includes: Bolt-action hunting rifle with scope, 12-gauge over-and-under shotgun, binoculars, rangefinder, wooden kayak paddle.
  - License: CC0.

### 2.4 Audio & Sound Effects
- **OpenGameArt.org & Freesound.org (Creative Commons 0):**
  - Ambient wilderness wind, duck quacks, goose honks, whitetail warning snorts, paddle water dips, rifle shot crack & canyon echo.

---

## 3. Phased Development Roadmap

### Phase 1: Foundations & Architecture (Complete)
- [x] Project architecture and Game Design Document (`GDD.md`).
- [x] Atmospheric Start Menu (`scenes/main_menu.tscn`).
- [x] First-person stalking controller (WASD, Stances, Noise tracking).
- [x] Working 3D Kayak controller with water buoyancy and stealth mechanics.
- [x] Global Wind & Scent Cone system (`WindSystem`).
- [x] In-Game Hunting HUD (Wind compass, Stance/Noise meter, Optics rangefinder).

### Phase 2: Visual Polish & First-Person Immersion (Immediate Next)
- [ ] Render 3D hunting rifle in the player's hands with scope/iron sight aiming.
- [ ] Scatter procedural pine trees, cattails/reeds, and river rocks across the landscape.
- [ ] Water surface shader with subtle waves and shoreline foam.

### Phase 3: Animal Models & Animated Behaviors
- [ ] Import animated Whitetail models (Idle grazing, Head-up sniffing, Sprinting).
- [ ] Connect state machine animations to the sensory alert level.
- [ ] Physical blood trails spawned on ground based on organ hit.

### Phase 4: Waterfowl & The Hunting Dog
- [ ] Deployable duck decoy spread from kayak.
- [ ] Duck call item (drawing flocks in).
- [ ] Dog "Fetch" command retrieving ducks from deep water.

### Phase 5: Career & Trophy Room
- [ ] 3D Trophy Inspection screen (X-ray shot review showing bullet path through organs).
- [ ] Local offline save game system (saving your trophy rack collection).
