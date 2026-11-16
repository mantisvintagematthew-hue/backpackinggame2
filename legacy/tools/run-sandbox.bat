@echo off
cd /d "%~dp0\.."
where godot >nul 2>nul
if errorlevel 1 (
  echo Add Godot 4.6.3 to PATH as godot.exe, or import project.godot in the Godot editor and press F5.
  pause
  exit /b 1
)
godot --path . -- %*
