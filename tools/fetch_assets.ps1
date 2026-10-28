# Downloads CC0 assets from Poly Haven (https://polyhaven.com - all assets are CC0 public domain)
$ProgressPreference = 'SilentlyContinue'
$root = Split-Path -Parent $PSScriptRoot
$models = @('fir_tree_01','pine_tree_01','shrub_01','shrub_02','fern_02','rock_moss_set_01','dead_tree_trunk','tree_stump_01','grass_medium_01','pine_sapling_medium')
$textures = @('forrest_ground_01','aerial_grass_rock','brown_mud_leaves_01')
$hdri = 'kloofendal_48d_partly_cloudy_puresky'

function Get-Gltf($id, $res) {
    $f = Invoke-RestMethod "https://api.polyhaven.com/files/$id" -TimeoutSec 60
    $g = $f.gltf.$res.gltf
    if (-not $g) { Write-Host "no gltf $res for $id"; return }
    $dir = Join-Path $root "assets/models/$id"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Invoke-WebRequest $g.url -OutFile (Join-Path $dir ([IO.Path]::GetFileName($g.url))) -TimeoutSec 300
    foreach ($p in $g.include.PSObject.Properties) {
        $out = Join-Path $dir $p.Name
        New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
        Invoke-WebRequest $p.Value.url -OutFile $out -TimeoutSec 300
    }
    Write-Host "model ok: $id"
}

function Get-Tex($id) {
    $f = Invoke-RestMethod "https://api.polyhaven.com/files/$id" -TimeoutSec 60
    $dir = Join-Path $root "assets/textures/$id"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $map = @{ 'Diffuse'='albedo'; 'nor_gl'='normal'; 'Rough'='rough' }
    foreach ($k in $map.Keys) {
        $u = $f.$k.'1k'.jpg.url
        if ($u) { Invoke-WebRequest $u -OutFile (Join-Path $dir "$($map[$k]).jpg") -TimeoutSec 300 }
    }
    Write-Host "texture ok: $id"
}

foreach ($m in $models) { try { Get-Gltf $m '1k' } catch { Write-Host "FAIL $m : $_" } }
foreach ($t in $textures) { try { Get-Tex $t } catch { Write-Host "FAIL $t : $_" } }
try {
    $f = Invoke-RestMethod "https://api.polyhaven.com/files/$hdri" -TimeoutSec 60
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'assets/sky') | Out-Null
    Invoke-WebRequest $f.hdri.'2k'.hdr.url -OutFile (Join-Path $root 'assets/sky/sky.hdr') -TimeoutSec 300
    Write-Host "hdri ok"
} catch { Write-Host "FAIL hdri: $_" }

# Animated Fox (glTF sample asset, CC-BY 4.0 - credit: PixelMannen / tomkranis / Khronos)
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'assets/models/fox') | Out-Null
    Invoke-WebRequest 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Fox/glTF-Binary/Fox.glb' -OutFile (Join-Path $root 'assets/models/fox/Fox.glb') -TimeoutSec 300
    Write-Host "fox ok"
} catch { Write-Host "FAIL fox: $_" }
