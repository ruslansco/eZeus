@echo off
setlocal
cd /d "%~dp0"
if not exist "Test Results" mkdir "Test Results"
if not exist "eZeus\godot\prepared-runtime.json" (
  echo Preparing the game files for this PC. The first run can take some time.
  "tools\godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "eZeus\godot" --editor --import --quit --log-file "%~dp0Test Results\import.log"
  if errorlevel 1 goto failed
)
:choose_scratch
set "EZEUS_PACKAGE_SCRATCH=%TEMP%\citybuilder-check-%RANDOM%-%RANDOM%-%RANDOM%"
if exist "%EZEUS_PACKAGE_SCRATCH%" goto choose_scratch
mkdir "%EZEUS_PACKAGE_SCRATCH%"
if errorlevel 1 goto failed
set "EZEUS_PACKAGE_RESULTS=%~dp0Test Results"
set "EZEUS_PACKAGE_RESULTS_ZIP=%~dp0Dell-test-results.zip"
echo The checks use disposable copies. Your saved games stay intact.
"tools\godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "eZeus\godot" --script res://scripts/review_windows_package.gd --log-file "%~dp0Test Results\test-runner.log" -- --silent
set "TEST_EXIT=%ERRORLEVEL%"
powershell.exe -NoLogo -NoProfile -Command "Compress-Archive -LiteralPath $env:EZEUS_PACKAGE_RESULTS -DestinationPath $env:EZEUS_PACKAGE_RESULTS_ZIP -Force"
if errorlevel 1 goto failed
if not "%TEST_EXIT%"=="0" goto failed
rmdir /s /q "%EZEUS_PACKAGE_SCRATCH%"
echo Checks finished. Send back Dell-test-results.zip from this folder.
pause
exit /b 0
:failed
echo A check failed. Keep Test Results and any Dell-test-results.zip that was produced.
pause
exit /b 1
