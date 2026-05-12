@echo off
chcp 65001 >nul
echo ==========================================
echo  AI资讯中心 - 打包部署文件
echo ==========================================
echo.

set "PROJECT_DIR=%~dp0..\.."
set "DEPLOY_PKG=%PROJECT_DIR%\..\ai-news-deploy"

echo 正在准备部署包...

:: 删除旧的打包目录
if exist "%DEPLOY_PKG%" rd /s /q "%DEPLOY_PKG%"

:: 创建打包目录结构
mkdir "%DEPLOY_PKG%\frontend"
mkdir "%DEPLOY_PKG%\backend"
mkdir "%DEPLOY_PKG%\deploy"

:: 复制前端文件 (排除 node_modules 和 .next/cache)
robocopy "%PROJECT_DIR%\frontend" "%DEPLOY_PKG%\frontend" /E /NFL /NDL /NJH /NJS ^
    /XD node_modules .next .git ^
    /XF .env.local

:: 复制后端文件
robocopy "%PROJECT_DIR%\backend" "%DEPLOY_PKG%\backend" /E /NFL /NDL /NJH /NJS ^
    /XD __pycache__ node_modules ^
    /XF news.db

:: 复制配置和部署文件
copy "%PROJECT_DIR%\ecosystem.config.js" "%DEPLOY_PKG%\" >nul
copy "%PROJECT_DIR%\deploy\nginx-win.conf" "%DEPLOY_PKG%\deploy\" >nul
copy "%PROJECT_DIR%\deploy\windows\setup.ps1" "%DEPLOY_PKG%\deploy\" >nul
copy "%PROJECT_DIR%\deploy\windows\deploy.ps1" "%DEPLOY_PKG%\deploy\" >nul

echo.
echo ==========================================
echo  打包完成！
echo  位置: %DEPLOY_PKG%
echo ==========================================
echo.
echo 通过 RDP 将此目录复制到服务器:
echo  C:\www\avenchoi.top\
echo.
echo 然后在 PowerShell (管理员) 中运行:
echo   cd C:\www\avenchoi.top\deploy
echo   powershell -ExecutionPolicy Bypass -File setup.ps1
echo   powershell -ExecutionPolicy Bypass -File deploy.ps1
echo.
pause
