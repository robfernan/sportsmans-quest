import os
import zipfile

dist = r"C:\Users\User\Documents\Projects\7. REA_ReverseEngineeringAnything\theHunterClassic\dist"
zip_path = os.path.join(dist, "SportsmansQuest_Windows_ReadyToPlay.zip")

if os.path.exists(zip_path):
    os.remove(zip_path)

with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    exe_path = os.path.join(dist, "SportsmansQuest.exe")
    pck_path = os.path.join(dist, "SportsmansQuest.pck")
    zf.write(exe_path, "SportsmansQuest.exe")
    zf.write(pck_path, "SportsmansQuest.pck")
    readme_content = """Sportsman's Quest: Whispering Pines Reserve
===============================================
Ultra-Optimized 100% Procedural 3D Hunting Game

HOW TO PLAY:
1. Double-click "SportsmansQuest.exe" to play.
2. Select "DAY EXPEDITION" or "NIGHT HUNT (CRYPTID HORROR MODE)" from Main Menu.

CONTROLS:
- W/A/S/D: Walk
- Shift: Sprint
- C: Crouch
- Z: Prone
- Right Click: Aim Optics (Scope / Binoculars)
- Left Click: Fire Weapon
- 1: .308 Bolt-Action Hunting Rifle
- 2: Roper Repeating 12GA Shotgun
- 3: Binoculars (Laser Rangefinder)
- 4: Grunt Call
- 5: Duck Whistle
- 6: Predator Squeaker
- R: Reload
- M: Huntermate Topo GPS Map & Logbook
- F: Range Zeroing (100m / 200m / 300m)
- G: Deploy Waterfowl Decoy
- B: Deploy Shoreline Blind
- K: Command Dog (Heel / Seek Blood / Retrieve)
- ESC: Menu / Pause / Exit
- F11: Fullscreen Toggle
"""
    zf.writestr("README.txt", readme_content)

print(f"Created {zip_path} ({os.path.getsize(zip_path):,} bytes)")
