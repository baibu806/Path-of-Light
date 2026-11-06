@echo off
setlocal
set "PROJECT=%~dp0"
set "ENGINE_DIR=%~dp0..\Godot_v4.7.2-stable_win64.exe"
set "ENGINE=%ENGINE_DIR%\Godot_v4.7.2-stable_win64.exe"
set "CONSOLE=%ENGINE_DIR%\Godot_v4.7.2-stable_win64_console.exe"

if not exist "%ENGINE%" (
  echo Godot 4.7.2 was not found next to the project folder.
  echo Please extract the entire ZIP before starting the game.
  pause
  exit /b 1
)

echo Importing game resources on this computer. The first launch may take a while...
"%CONSOLE%" --headless --editor --import --path "%PROJECT%" --quiet
if errorlevel 1 (
  echo Resource import failed. Please send a screenshot of this window to the project team.
  pause
  exit /b 1
)

"%ENGINE%" --path "%PROJECT%"
endlocal
