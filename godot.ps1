$ErrorActionPreference = "Stop"

$godotExecutable = Join-Path $PSScriptRoot ".godot\tools\godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe"

if (-not (Test-Path -LiteralPath $godotExecutable)) {
    throw "Godot 4.6.3 executable not found at: $godotExecutable"
}

& $godotExecutable --path $PSScriptRoot @args
exit $LASTEXITCODE
