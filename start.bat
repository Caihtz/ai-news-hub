@echo off
chcp 65001 >nul
title AI News Hub - 启动器

echo ========================================
echo    AI News Hub 一键启动
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] 检查Python环境...
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到Python，请先安装Python 3
    pause
    exit /b 1
)
echo [OK] Python已就绪

echo.
echo [2/3] 检查依赖...
pip show flask >nul 2>&1
if errorlevel 1 (
    echo [安装] 正在安装依赖...
    pip install flask flask-cors feedparser requests lxml >nul 2>&1
)
echo [OK] 依赖已就绪

echo.
echo [3/3] 启动服务...
echo.

:: 启动后端API
start "AI-News-API" cmd /k "cd /d %~dp0\backend && python collector.py api"

:: 等待后端启动
timeout /t 3 /nobreak >nul

:: 启动前端
start "AI-News-Frontend" cmd /k "cd /d %~dp0\frontend && npm run dev"

echo.
echo ========================================
echo    服务已启动!
echo ========================================
echo.
echo   后端API: http://localhost:3001
echo   前端网站: http://localhost:3000
echo.
echo   健康检查: http://localhost:3001/api/stats
echo   手动采集: http://localhost:3001/api/collect
echo.
echo 5秒后自动关闭此窗口...
timeout /t 5 /nobreak >nul
