@echo off
setlocal
cd /d "%~dp0"
if not exist "Test Results" mkdir "Test Results"
if not exist "eZeus\godot\.godot\extension_list.cfg" (
  echo Preparing the game files for this PC. The first run can take a few minutes.
  "tools\godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "eZeus\godot" --editor --import --quit --log-file "%~dp0Test Results\import.log"
  if errorlevel 1 goto failed
)
"tools\godot\Godot_v4.6.3-stable_win64.exe" --path "eZeus\godot" --rendering-method mobile --log-file "%~dp0Test Results\play.log"
if errorlevel 1 goto failed
exit /b 0
:failed
echo The game could not start. Keep the files in Test Results so we can diagnose it.
pause
exit /b 1
