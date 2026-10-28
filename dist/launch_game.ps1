# Launches the full production Godot 4 masterpiece with all 3D systems
$PSScriptRoot_Dir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Engine = Join-Path $PSScriptRoot_Dir "SportsmansQuest.exe"
$Pack = Join-Path $PSScriptRoot_Dir "SportsmansQuest.pck"

if (Test-Path $Pack) {
    & $Engine --main-pack $Pack
} else {
    Write-Host "Missing game package: $Pack" -ForegroundColor Red
}
