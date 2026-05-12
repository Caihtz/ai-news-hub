@echo off
chcp 65001 >nul
echo ========================================
echo   AI News Hub - Windows定时任务配置
echo ========================================
echo.

set SCRIPT_PATH=%~dp0scheduler_task.bat
set TASK_NAME=AINewsCollector

echo 即将创建定时任务:
echo   任务名称: %TASK_NAME%
echo   执行频率: 每小时一次
echo   执行脚本: %SCRIPT_PATH%
echo.
echo 警告: 这将覆盖现有的同名任务
echo.

set /p confirm=确认创建? (Y/N):
if /i not "%confirm%"=="Y" goto end

echo.
echo [创建定时任务...]

schtasks /create /tn "%TASK_NAME%" /tr "\"%SCRIPT_PATH%\"" /sc HOURLY /st 00:05 /f

if %errorlevel%==0 (
    echo.
    echo [成功] 定时任务已创建!
    echo.
    echo 可用命令:
    echo   查看任务: schtasks /query /tn "%TASK_NAME%"
    echo   删除任务: schtasks /delete /tn "%TASK_NAME%" /f
    echo   立即执行: schtasks /run /tn "%TASK_NAME%"
) else (
    echo.
    echo [失败] 请以管理员身份运行此脚本
    echo 右键点击 "以管理员身份运行"
)

:end
echo.
pause
