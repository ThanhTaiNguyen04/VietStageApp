$icons = @('flame', 'sparkles', 'trophy', 'calendar-days', 'camera')
$baseUrl = 'https://unpkg.com/lucide-static@latest/icons/'
$outDir = 'assets/textures/lucide'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir }
foreach ($icon in $icons) {
    Invoke-WebRequest -Uri ($baseUrl + $icon + '.svg') -OutFile (Join-Path $outDir ($icon + '.svg'))
}
