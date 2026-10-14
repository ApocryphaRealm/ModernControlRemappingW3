@echo off
rem Modern Control Remapping (The Witcher 3) - puts the controller map into the game's settings. Close the game first.
rem Drag a settings folder onto this file to install into that folder instead of Documents\The Witcher 3.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %1
pause
