# The Windows program the way a person gets it: install with the installer (silently), open it,
# check its window and take a screenshot, open it a second time (the first window comes forward,
# no second copy), then uninstall and check nothing is left. Run on GitHub's Windows machines,
# which have no graphics card, so it also shows the program draws without one.
#   pwsh tool/windows_smoke.ps1 installer\SlopeCalculator-Setup.exe screenshot.png
param([Parameter(Mandatory)] [string] $Installer, [string] $Screenshot = 'windows-smoke.png')
$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'SlopeCalculator'
$exe = Join-Path $dir 'SlopeCalculator.exe'
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\SlopeCalculator'
function Check($ok, $what) { if (-not $ok) { throw "FAILED: $what" } else { Write-Host "ok  $what" } }
function WaitFor([scriptblock] $test, [int] $seconds) {
  for ($i = 0; $i -lt $seconds * 2; $i++) { if (& $test) { return $true }; Start-Sleep -Milliseconds 500 }
  return $false
}

# 1. install
Start-Process -FilePath $Installer -ArgumentList '/S' -Wait
Check (Test-Path $exe) 'installed to %LOCALAPPDATA%\SlopeCalculator'
foreach ($f in 'flutter_windows.dll', 'data\app.so', 'data\icudtl.dat', 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll', 'Uninstall.exe') {
  Check (Test-Path (Join-Path $dir $f)) "has $f"
}
Check (Test-Path $key) 'listed in Settings > Apps'
Check ((Get-ItemProperty $key).DisplayName -eq 'Slope Calculator') 'listed as "Slope Calculator"'
Check (Test-Path (Join-Path ([Environment]::GetFolderPath('Programs')) 'Slope Calculator\Slope Calculator.lnk')) 'Start menu shortcut'
Check (Test-Path (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Slope Calculator.lnk')) 'desktop shortcut'

# 2. open it
$p = Start-Process -FilePath $exe -PassThru
Check (WaitFor { $p.Refresh(); $p.MainWindowHandle -ne 0 -and $p.MainWindowTitle -eq 'Slope Calculator' } 30) 'opens a window titled "Slope Calculator"'
Start-Sleep -Seconds 8 # first frame, fonts, the sign-in screen
Check (-not $p.HasExited) 'still running after 8 seconds'

# the screenshot, and a check that the window isn't blank (it drew without a graphics card)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
[System.Drawing.Graphics]::FromImage($bmp).CopyFromScreen($screen.Location, [System.Drawing.Point]::Empty, $screen.Size)
$bmp.Save($Screenshot, [System.Drawing.Imaging.ImageFormat]::Png)
$colours = @{}
for ($x = 0; $x -lt $screen.Width; $x += 23) { for ($y = 0; $y -lt $screen.Height; $y += 19) { $colours[$bmp.GetPixel($x, $y).ToArgb()] = 1 } }
Write-Host "screenshot: $Screenshot ($($screen.Width)x$($screen.Height), $($colours.Count) colours)"
Check ($colours.Count -gt 20) 'the screen shows a drawn window, not a blank one'

# 3. a second start brings the first window forward instead of opening another copy
Start-Process -FilePath $exe
Start-Sleep -Seconds 5
Check (@(Get-Process SlopeCalculator -ErrorAction SilentlyContinue).Count -eq 1) 'only one copy runs'

# 4. uninstall
Start-Process -FilePath (Join-Path $dir 'Uninstall.exe') -ArgumentList '/S' -Wait
Check (WaitFor { -not (Test-Path $dir) } 30) 'uninstall removes the folder'
Check (-not (Test-Path $key)) 'uninstall removes it from Settings > Apps'
Check (-not (Get-Process SlopeCalculator -ErrorAction SilentlyContinue)) 'uninstall closes the program'
Write-Host 'Windows install, open and uninstall: all good'
