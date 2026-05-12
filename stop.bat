@echo off
chcp 65001 >nul
title AI News Hub - 停止服务

echo ========================================
echo    AI News Hub - 停止所有服务
echo ========================================
echo.

echo [停止所有Node和Python进程...]
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM python.exe >nul 2>&1

echo.
echo [完成] 所有服务已停止
echo.
pause
