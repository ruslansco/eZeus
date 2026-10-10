param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [int]$Jobs = 4
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$Repo = Split-Path -Parent $PSScriptRoot
$Workspace = Split-Path -Parent $Repo
$Build = Join-Path $Repo "build-godot-windows"
$Stage = Join-Path $Build "staged-extension"
$Bindings = Join-Path $Workspace "tools\godot-cpp"
$Pin = "507ed9d840c01a3c5b2a39af8bb4000bfac30bf5"

function Run([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed ($LASTEXITCODE)." }
}
if ($env:OS -ne "Windows_NT") { throw "Run this on a Windows x64 PC." }
if ($Repo.Contains("&") -or $Repo -match "[^\x00-\x7F]") {
    throw "Use a short ASCII folder without '&', for example C:\CityBuilder\eZeus. SDL's old header-copy rule needs this."
}
if (-not (Test-Path -LiteralPath $Godot)) { throw "Godot executable missing: $Godot" }
$Version = & $Godot --version
if ($LASTEXITCODE -ne 0 -or $Version -notmatch "^4\.6\.3\.") { throw "This test build requires Godot 4.6.3, received $Version." }
foreach ($Program in @("git","cmake")) { Get-Command $Program -ErrorAction Stop | Out-Null }
if ($Jobs -lt 1 -or $Jobs -gt 32) { throw "Jobs must be 1–32; use 2 on an 8 GB machine." }

if (-not (Test-Path (Join-Path $Bindings "CMakeLists.txt"))) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $Bindings) | Out-Null
    Run "git" @("clone","--no-checkout","https://github.com/godotengine/godot-cpp.git",$Bindings)
    Run "git" @("-C",$Bindings,"checkout","--detach",$Pin)
    Run "git" @("-C",$Bindings,"submodule","update","--init","--recursive")
}
$Actual = & git -C $Bindings rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $Actual.Trim() -ne $Pin) {
    throw "Existing godot-cpp has a different revision. Preserve it and prepare the pinned revision in a separate workspace."
}
New-Item -ItemType Directory -Force $Stage | Out-Null
Run "cmake" @("-S",$Repo,"-B",$Build,"-G","Visual Studio 17 2022","-A","x64",
    "-DEZEUS_BUILD_GODOT_EXTENSION=ON","-DEZEUS_GODOT_OUTPUT_DIRECTORY=$Stage")
Run "cmake" @("--build",$Build,"--config","Release","--target","ezeus_godot","--parallel",[string]$Jobs)
if (-not (Test-Path (Join-Path $Stage "ezeus_godot.dll"))) { throw "No Windows extension produced." }

# Stage on a new inode. A mapped Windows DLL may refuse replacement; preserve the
# installed file and fail instead of stopping another game or deleting its DLL.
$Bin = Join-Path $Repo "godot\bin"
foreach ($Library in Get-ChildItem -LiteralPath $Stage -Filter "*.dll") {
    $Destination = Join-Path $Bin $Library.Name
    $Temporary = Join-Path $Bin (".staged-"+[guid]::NewGuid().ToString()+".dll")
    try {
        Copy-Item -LiteralPath $Library.FullName -Destination $Temporary
        if (Test-Path -LiteralPath $Destination) {
            [System.IO.File]::Replace($Temporary,$Destination,$null)
        } else { [System.IO.File]::Move($Temporary,$Destination) }
    } finally { if (Test-Path -LiteralPath $Temporary) { Remove-Item -LiteralPath $Temporary } }
}
$Manifest = Get-ChildItem -LiteralPath $Stage -Filter "*.dll" | ForEach-Object {
    [pscustomobject]@{ file=$_.Name; bytes=$_.Length; sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
}
$Manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Stage "dll-manifest.json") -Encoding UTF8
Copy-Item -LiteralPath (Join-Path $Repo "presentation\godot\ezeus.gdextension") -Destination (Join-Path $Bin "ezeus.gdextension")
Run $Godot @("--headless","--path",(Join-Path $Repo "godot"),"--editor","--import","--quit")
Write-Host "Windows development extension staged and imported. Run the Windows checks before claiming platform support."
