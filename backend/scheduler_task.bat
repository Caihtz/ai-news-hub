@echo off
chcp 65001 >nul
echo ========================================
echo   AI News Hub - 定时采集脚本
echo   执行时间: %date% %time%
echo ========================================
echo.

cd /d %~dp0

echo [1/3] 清理过期数据并采集新内容...
python collector.py collect

echo.
echo [2/3] 检查数据库状态...
python -c ^
import sqlite3^
from datetime import datetime^
^
conn = sqlite3.connect('news.db')^
c = conn.cursor()^
c.execute('SELECT COUNT(*) FROM articles')^
total = c.fetchone()[0]^
c.execute('SELECT MIN(created_at), MAX(created_at) FROM articles')^
min_d, max_d = c.fetchone()^
conn.close()^
^
print(f'当前数据库: {total} 条新闻')^
print(f'记录时间范围: {min_d[:10] if min_d else \"N/A\"} ~ {max_d[:10] if max_d else \"N/A\"}')^
"

echo.
echo [3/3] 采集完成!
echo ========================================
