@echo off
chcp 65001 >nul
echo ========================================
echo   AI News Hub - 健康检查
echo ========================================
echo.

set API_OK=0
set FRONTEND_OK=0

echo [检查后端API...]
curl -s -o nul -w "HTTP状态: %%{http_code}" http://localhost:3001/api/stats
echo.
curl -s http://localhost:3001/api/stats | findstr "success" >nul
if %errorlevel%==0 (
    echo [OK] 后端API正常
    set API_OK=1
) else (
    echo [FAIL] 后端API无响应
)

echo.
echo [检查前端...]
curl -s -o nul -w "HTTP状态: %%{http_code}" http://localhost:3000
echo.

echo.
echo [数据库状态...]
python -c ^
import sqlite3^
from datetime import datetime, timedelta^
^
conn = sqlite3.connect('news.db')^
c = conn.cursor()^
c.execute('SELECT COUNT(*) FROM articles')^
total = c.fetchone()[0]^
c.execute('SELECT MIN(created_at), MAX(created_at) FROM articles')^
min_d, max_d = c.fetchone()^
c.execute('SELECT COUNT(*) FROM articles WHERE created_at < ?', ((datetime.now() - timedelta(days=7)).isoformat(),)))^
old = c.fetchone()[0]^
conn.close()^
^
print(f'  总记录数: {total}')^
print(f'  时间范围: {min_d[:19] if min_d else \"N/A\"} ~ {max_d[:19] if max_d else \"N/A\"}')^
print(f'  过期记录: {old} (将被清理)')^

echo.
echo ========================================
echo   服务状态总结
echo ========================================
if %API_OK%==1 (
    echo   [OK] 后端API:  http://localhost:3001
) else (
    echo   [FAIL] 后端API: http://localhost:3001
)
echo   [INFO] 前端网站: http://localhost:3000
echo ========================================
echo.
