param(
    [ValidateSet("debug", "release", "both")]
    [string]$Target = "both",
    [int]$Jobs = 12
)

$ErrorActionPreference = "Stop"

$python = Join-Path $PSScriptRoot ".godot\tools\python-3.13.13\python.exe"
$sconsPath = Join-Path $PSScriptRoot ".godot\tools\scons-4.10.1"
$mingwRoot = Join-Path $PSScriptRoot ".godot\tools\llvm-mingw-20260616-ucrt-x86_64"
$mingwBin = Join-Path $mingwRoot "bin"

foreach ($requiredPath in @($python, $sconsPath, $mingwBin)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required build tool not found: $requiredPath"
    }
}

$env:PYTHONPATH = $sconsPath
$env:PATH = "$mingwBin;$env:PATH"
$mingwArgument = $mingwRoot.Replace("\", "/")

$targets = switch ($Target) {
    "debug" { @("template_debug") }
    "release" { @("template_release") }
    default { @("template_debug", "template_release") }
}

foreach ($buildTarget in $targets) {
    & $python -m SCons -j $Jobs `
        platform=windows `
        target=$buildTarget `
        arch=x86_64 `
        api_version=4.6 `
        use_mingw=yes `
        use_llvm=yes `
        mingw_prefix=$mingwArgument

    if ($LASTEXITCODE -ne 0) {
        throw "GDExtension build failed for target: $buildTarget"
    }
}
