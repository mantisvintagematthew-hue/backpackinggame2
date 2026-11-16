@echo off
cd /d "%~dp0\.."
if not defined GODOT_BIN set GODOT_BIN=godot
"%GODOT_BIN%" --path . %*
