@echo off
title Instalacao nativa E-commerce Banco de Dados II
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\instalar-nativo-windows.ps1"
if errorlevel 1 pause
