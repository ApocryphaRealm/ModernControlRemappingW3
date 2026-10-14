@echo off
rem Modern Control Remapping (The Witcher 3) - puts the settings files back as they were before the first controller map install.
rem Drag a settings folder onto this file to restore that folder instead of Documents\The Witcher 3.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Uninstall %1
pause
