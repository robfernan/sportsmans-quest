# Project ApexHunter (Working Title)
## Game Design & Technical Architecture Document (GDD)
**Target Type:** Single-Player, 100% Offline Tactical Hunting Simulation  
**Engines:** Godot 4 (Prototyping) / Unreal Engine 5 (High-Fidelity Production)

---

## 1. Core Vision & Design Pillars

### 1.1 Design Pillars
1. **Patience Over Pacing:** No arcade sprint-and-shoot. Animals react realistically to distant disturbance; careless movement spooks animals hundreds of meters away.
2. **Deterministic & Authentic Ballistics:** Bullet behavior is determined by drag coefficients, muzzle velocity, wind drift, expansion, and multi-layer organ penetration.
3. **100% Fully Offline:** Complete local save game storage, zero server requirement, and persistent animal populations across hunting sessions.
4. **Physicalized Tracking:** Blood splatters reflect the organ struck (e.g. bubbly pink for lungs, dark crimson for liver), while ground tracks reflect animal speed and weight.

---

## 2. Sensory Perception System (AI Detection Math)

Animals evaluate player threat through three distinct sensory channels:

```
Total Threat Level = (VisualDetection * LightFactor) + (AuditoryDetection * GroundTypeFactor) + (ScentDetection * WindAlignment)
```

### 2.1 Scent & Wind Simulation
- Wind has two variables: `WindDirection` (vector) and `WindSpeed` (m/s).
- The player continuously generates an expanding conical scent plume in the direction of the wind:
  $$\text{ScentAngle} = \arccos(\hat{v}_{\text{wind}} \cdot \hat{v}_{\text{to\_animal}})$$
- If the animal is within the scent cone ($\text{ScentAngle} < \theta_{\text{cone}}$) and within $\text{Distance} < D_{\max}$, scent detection escalates rapidly.

### 2.2 Auditory Detection & Acoustic Occlusion
- Player noise output depends on stance and surface:
  - Prone: 5 dB
  - Crouched: 15 dB
  - Walking: 40 dB
  - Sprinting: 75 dB
  - Brush / Dry Grass modifier: +20 dB
- Sound drops off by inverse-square distance and raycast terrain occlusion (hills and rock formations muffle player sound).

### 2.3 Visual Detection
- Dependent on:
  - Player silhouette (Crouching / Prone reduces exposure by 40% / 75%).
  - Foliage concealment (percentage of camera occlusion between animal eyes and player root).
  - Sun angle and shadow masking.

---

## 3. Animal Behavior State Machine

```
              ┌───────────────┐
              │     IDLE      │ (Feeding / Drinking / Resting)
              └───────┬───────┘
                      │ Threat > 20%
              ┌───────▼───────┐
              │     WARY      │ (Head up, sniffing, looking around)
              └───────┬───────┘
                      │ Threat > 60%
              ┌───────▼───────┐
              │     ALERT     │ (Warning call / Stomp, herd prepares)
              └───────┬───────┘
                      │ Threat > 85% or Gunshot
              ┌───────▼───────┐
              │    FLEEING    │ (Fast sprint away downwind / toward dense brush)
              └───────┬───────┘
                      │ After 800m+ & Threat drops to 0
              ┌───────▼───────┐
              │  RELOCATING   │ (Wary trot to alternative reserve zone)
              └───────────────┘
```

---

## 4. Ballistics & Terminal Anatomy

### 4.1 Projectile Physics
- Gravity drop calculated per tick: $\vec{p}(t + \Delta t) = \vec{p}(t) + \vec{v}(t)\Delta t + \frac{1}{2}\vec{g}\Delta t^2$
- Aerodynamic drag based on projectile G1/G7 ballistic coefficient.
- Crosswind drift applied orthogonally to the velocity vector.

### 4.2 Organ Hitboxes & Lethality
Animals possess internal anatomical collision zones:
1. **Brain / Upper Spine:** Instant collapse / immediate harvest.
2. **Heart:** Massive bleed rate, runs 20–40 meters before collapsing.
3. **Double Lungs:** High bleed rate, frothy blood trails, runs 50–100 meters.
4. **Single Lung / Liver:** Medium bleed rate, extended tracking required (150–300 meters).
5. **Intestines / Flesh:** Very low bleed rate, animal may survive or require extensive tracking over kilometers.

---

## 5. Directory & Module Roadmap

- `core/`: Constants, math helpers, wind vector calculations.
- `ai/`: Animal sensory cones, state machine, herd flocking logic.
- `ballistics/`: Bullet trajectory solver, hit registration, organ damage calculation.
- `tracking/`: Ground footprints, blood decals, spoor decay logic.
- `ui/`: Radial pie menu, harvest inspection screen, rangefinder/binocular overlay.
