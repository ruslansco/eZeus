param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [double]$SoakMinutes = 0
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$Repo = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $Repo "godot\bin\ezeus_godot.dll"))) {
    throw "Build the Windows extension first with tools\build_godot_windows.ps1."
}
Get-Command python -ErrorAction Stop | Out-Null
Push-Location $Repo
try {
	& python tools\review_save_reliability.py --godot $Godot --headless
	if ($LASTEXITCODE -ne 0) { throw "Windows save/recovery checks failed. Preserve the log in godot\captures." }
    # The runner verifies the fixture/player preferences and isolates every save.
    & python tools\review_release_performance.py --godot $Godot --soak-minutes $SoakMinutes
    if ($LASTEXITCODE -ne 0) { throw "Windows performance checks failed. Preserve the log in godot\captures." }
} finally { Pop-Location }
