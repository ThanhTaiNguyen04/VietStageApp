$wshell = New-Object -ComObject wscript.shell
$process = Start-Process -FilePath "E:\vietStage\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" -ArgumentList "res://scenes/VirtualMusicRoom.tscn" -PassThru -WindowStyle Normal

# Wait for the scene to load and render
Start-Sleep -Seconds 5

# Activate the window
$success = $wshell.AppActivate('VietStage (DEBUG)')
Write-Host "AppActivate success: $success"
Start-Sleep -Milliseconds 500

# Take screenshot
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)

$artifactPath = "C:\Users\PC\.gemini\antigravity-ide\brain\9967b6bb-d644-4359-ab4b-48cbae3a0964\music_room_with_mai.png"
$bitmap.Save($artifactPath, [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()

Write-Host "Screenshot saved to $artifactPath"

# Kill the process
Stop-Process -Id $process.Id -Force
Write-Host "Process terminated."
