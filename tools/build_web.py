import os
import shutil
import zipfile
import json
import subprocess

PROJECT_DIR = r"C:\Users\User\Documents\Projects\7. REA_ReverseEngineeringAnything\theHunterClassic"
TEMPLATE_ZIP = r"C:\Users\User\AppData\Roaming\Godot\export_templates\4.7.2.stable\web_nothreads_release.zip"
GODOT_CONSOLE = r"C:\Users\User\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
WEB_DIR = os.path.join(PROJECT_DIR, "dist", "web_build")
ZIP_OUTPUT = os.path.join(PROJECT_DIR, "dist", "SportsmansQuest_Web.zip")

if os.path.exists(WEB_DIR):
    shutil.rmtree(WEB_DIR)
os.makedirs(WEB_DIR, exist_ok=True)

print("1. Exporting project PCK...")
pck_path = os.path.join(WEB_DIR, "index.pck")
res = subprocess.run([GODOT_CONSOLE, "--headless", "--path", PROJECT_DIR, "--export-pack", "Web", pck_path], capture_output=True, text=True)
if res.returncode != 0:
    print("PCK Export failed:", res.stderr)
    exit(1)
pck_size = os.path.getsize(pck_path)
print(f"PCK Exported successfully ({pck_size:,} bytes).")

print("2. Unpacking Web templates...")
with zipfile.ZipFile(TEMPLATE_ZIP, 'r') as zf:
    zf.extractall(WEB_DIR)

# Rename files to uniform 'index.*'
renames = {
    "godot.wasm": "index.wasm",
    "godot.audio.worklet.js": "index.audio.worklet.js",
    "godot.audio.position.worklet.js": "index.audio.position.worklet.js",
    "godot.service.worker.js": "index.service.worker.js",
    "godot.offline.html": "index.offline.html",
}
for src, dst in renames.items():
    sp = os.path.join(WEB_DIR, src)
    dp = os.path.join(WEB_DIR, dst)
    if os.path.exists(sp):
        if os.path.exists(dp): os.remove(dp)
        os.rename(sp, dp)

wasm_size = os.path.getsize(os.path.join(WEB_DIR, "index.wasm"))

# Modify index.js from godot.js
with open(os.path.join(WEB_DIR, "godot.js"), "r", encoding="utf-8") as f:
    js_content = f.read()

# Replace references to godot with index
js_content = js_content.replace('godot.web.template_release.wasm32.nothreads.wasm', 'index.wasm')
with open(os.path.join(WEB_DIR, "index.js"), "w", encoding="utf-8") as f:
    f.write(js_content)
os.remove(os.path.join(WEB_DIR, "godot.js"))

# Copy coi-serviceworker
coi_src = os.path.join(PROJECT_DIR, "dist", "coi-serviceworker.min.js")
if os.path.exists(coi_src):
    shutil.copy(coi_src, os.path.join(WEB_DIR, "coi-serviceworker.min.js"))

print("3. Generating index.html with Fullscreen and Focus controls...")
config = {
    "args": [],
    "canvasResizePolicy": 2,
    "ensureCrossOriginIsolationHeaders": False,
    "executable": "index",
    "experimentalVK": False,
    "fileSizes": {
        "index.pck": pck_size,
        "index.wasm": wasm_size
    },
    "focusCanvas": True,
    "gdextensionLibs": [],
    "mainPack": "index.pck",
    "serviceWorker": ""
}
config_json = json.dumps(config)

html_template = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <script src="coi-serviceworker.min.js"></script>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0">
    <title>Sportsman's Quest: Whispering Pines Reserve</title>
    <style>
        html, body, #canvas {{
            margin: 0;
            padding: 0;
            border: 0;
            width: 100%;
            height: 100%;
        }}
        body {{
            color: white;
            background-color: #08060a;
            overflow: hidden;
            touch-action: none;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }}
        #canvas {{
            display: block;
            width: 100%;
            height: 100%;
        }}
        #canvas:focus {{
            outline: none;
        }}
        #web-ui-bar {{
            position: absolute;
            top: 10px;
            right: 12px;
            z-index: 1000;
            display: flex;
            gap: 8px;
            pointer-events: auto;
        }}
        .web-btn {{
            background: rgba(220, 95, 18, 0.92);
            color: #ffffff;
            border: 1px solid rgba(255, 255, 255, 0.25);
            padding: 6px 14px;
            border-radius: 5px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            box-shadow: 0 2px 6px rgba(0,0,0,0.6);
            transition: all 0.15s ease;
        }}
        .web-btn:hover {{
            background: #ff7524;
            transform: translateY(-1px);
        }}
        #status, #status-splash, #status-progress {{
            position: absolute;
            left: 0;
            right: 0;
        }}
        #status, #status-splash {{
            top: 0;
            bottom: 0;
        }}
        #status {{
            background-color: #060408;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            visibility: hidden;
        }}
        #status-progress {{
            display: none;
            bottom: 12%;
            width: 50%;
            margin: 0 auto;
            height: 8px;
            border-radius: 4px;
            overflow: hidden;
        }}
        #status-notice {{
            display: none;
            background-color: #5b2828;
            border-radius: 0.5rem;
            border: 1px solid #9b3939;
            color: #f0f0f0;
            padding: 1rem;
            text-align: center;
            margin: 1rem;
            max-width: 600px;
        }}
    </style>
</head>
<body>
    <div id="web-ui-bar">
        <button class="web-btn" onclick="toggleFullscreen()">⛶ Fullscreen</button>
    </div>

    <canvas id="canvas" tabindex="0">
        Your browser does not support the canvas tag.
    </canvas>

    <div id="status">
        <div style="font-size: 24px; font-weight: bold; margin-bottom: 20px; color: #ff9d42; letter-spacing: 1px;">
            SPORTSMAN'S QUEST: WHISPERING PINES
        </div>
        <div style="font-size: 14px; color: #aaa; margin-bottom: 15px;">Loading Whispering Pines Reserve...</div>
        <progress id="status-progress"></progress>
        <div id="status-notice"></div>
    </div>

    <script src="index.js"></script>
    <script>
        const GODOT_CONFIG = {config_json};
        const GODOT_THREADS_ENABLED = false;
        const engine = new Engine(GODOT_CONFIG);

        function toggleFullscreen() {{
            if (!document.fullscreenElement) {{
                if (document.documentElement.requestFullscreen) {{
                    document.documentElement.requestFullscreen();
                }} else if (document.documentElement.webkitRequestFullscreen) {{
                    document.documentElement.webkitRequestFullscreen();
                }}
            }} else {{
                if (document.exitFullscreen) {{
                    document.exitFullscreen();
                }}
            }}
        }}

        (function () {{
            const statusOverlay = document.getElementById('status');
            const statusProgress = document.getElementById('status-progress');
            const statusNotice = document.getElementById('status-notice');
            const canvas = document.getElementById('canvas');

            let initializing = true;
            let statusMode = '';

            function setStatusMode(mode) {{
                if (statusMode === mode || !initializing) return;
                if (mode === 'hidden') {{
                    statusOverlay.remove();
                    initializing = false;
                    return;
                }}
                statusOverlay.style.visibility = 'visible';
                statusProgress.style.display = mode === 'progress' ? 'block' : 'none';
                statusNotice.style.display = mode === 'notice' ? 'block' : 'none';
                statusMode = mode;
            }}

            function setStatusNotice(text) {{
                while (statusNotice.lastChild) statusNotice.removeChild(statusNotice.lastChild);
                text.split('\\n').forEach(line => {{
                    statusNotice.appendChild(document.createTextNode(line));
                    statusNotice.appendChild(document.createElement('br'));
                }});
            }}

            function displayFailureNotice(err) {{
                console.error(err);
                setStatusNotice(err instanceof Error ? err.message : String(err));
                setStatusMode('notice');
                initializing = false;
            }}

            // Clicking canvas guarantees focus and pointer lock for web gameplay
            canvas.addEventListener('click', () => {{
                canvas.focus();
            }});

            const missing = Engine.getMissingFeatures({{ threads: false }});
            if (missing.length !== 0) {{
                displayFailureNotice('Browser missing WebGL features:\\n' + missing.join('\\n'));
            }} else {{
                setStatusMode('progress');
                engine.startGame({{
                    'onProgress': function (current, total) {{
                        if (current > 0 && total > 0) {{
                            statusProgress.value = current;
                            statusProgress.max = total;
                        }} else {{
                            statusProgress.removeAttribute('value');
                            statusProgress.removeAttribute('max');
                        }}
                    }},
                }}).then(() => {{
                    setStatusMode('hidden');
                    canvas.focus();
                }}, displayFailureNotice);
            }}
        }})();
    </script>
</body>
</html>
"""

with open(os.path.join(WEB_DIR, "index.html"), "w", encoding="utf-8") as f:
    f.write(html_template)

# Also create godot.pck as a symlink or copy so any engine fallback will also succeed 100%
shutil.copyfile(pck_path, os.path.join(WEB_DIR, "godot.pck"))
shutil.copyfile(os.path.join(WEB_DIR, "index.wasm"), os.path.join(WEB_DIR, "godot.wasm"))

if os.path.exists(os.path.join(WEB_DIR, "godot.html")):
    os.remove(os.path.join(WEB_DIR, "godot.html"))

print("4. Packaging into SportsmansQuest_Web.zip...")
if os.path.exists(ZIP_OUTPUT):
    os.remove(ZIP_OUTPUT)

with zipfile.ZipFile(ZIP_OUTPUT, 'w', zipfile.ZIP_DEFLATED) as zf:
    for filename in os.listdir(WEB_DIR):
        file_path = os.path.join(WEB_DIR, filename)
        if os.path.isfile(file_path):
            zf.write(file_path, arcname=filename)
            print(f"  + {filename} ({os.path.getsize(file_path):,} bytes)")

print(f"\nSUCCESS: Created {ZIP_OUTPUT} ({os.path.getsize(ZIP_OUTPUT):,} bytes)")
