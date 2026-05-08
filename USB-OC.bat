@echo off
chcp 65001 >nul
title Portable AI USB

powershell -NoProfile -ExecutionPolicy Bypass -NoExit -Command "& '.\tools\enter-portable.ps1'"
