@echo off
chcp 65001 >nul
echo ========================================
echo   AI News Hub - 服务管理脚本
echo ========================================
echo.

:menu
echo 请选择操作:
echo [1] 启动所有服务 (后端API + 前端)
echo [2] 仅启动后端API (端口3001)
echo [3] 仅启动前端 (端口3000)
echo [4] 停止所有服务
echo [5] 运行采集并更新数据
echo [6] 查看服务状态
echo [0] 退出
echo.
set /p choice=请输入选项:

if "%choice%"=="1" goto start_all
if "%choice%"=="2" goto start_backend
if "%choice%"=="3" goto start_frontend
if "%choice%"=="4" goto stop_all
if "%choice%"=="5" goto collect
if "%choice%"=="6" goto status
if "%choice%"=="0" goto end

echo 无效选项，请重新选择
echo.
goto menu

:start_all
echo [启动后端API...]
start "AI-News-Backend" cmd /k "cd /d %~dp0 && python -c ^
from flask import Flask, jsonify, request^
from flask_cors import CORS^
import sqlite3^
import json^
from datetime import datetime, timedelta^
^
app = Flask(__name__)^
CORS(app)^
^
def get_db():^
    conn = sqlite3.connect('news.db')^
    conn.row_factory = sqlite3.Row^
    return conn^
^
@app.route('/api/news')^
def get_news():^
    page = int(request.args.get('page', 1))^
    page_size = int(request.args.get('pageSize', 12))^
    channel = request.args.get('channel', 'all')^
    keyword = request.args.get('keyword', '')^
    ^
    conn = get_db()^
    c = conn.cursor()^
    ^
    sql = 'SELECT * FROM articles WHERE 1=1'^
    params = []^
    ^
    if channel != 'all':^
        sql += ' AND source = ?'^
        params.append(channel)^
    ^
    if keyword:^
        sql += ' AND (title LIKE ? OR summary LIKE ?)'^
        params.extend([f'%{keyword}%', f'%{keyword}%'])^
    ^
    sql += ' ORDER BY score DESC, published_at DESC'^
    offset = (page - 1) * page_size^
    sql += f' LIMIT {page_size} OFFSET {offset}'^
    ^
    c.execute(sql, params)^
    rows = c.fetchall()^
    ^
    count_sql = 'SELECT COUNT(*) FROM articles WHERE 1=1' + (' AND source = ?' if channel != 'all' else '')^
    c.execute(count_sql, params[:1] if channel != 'all' else [])^
    total = c.fetchone()[0]^
    conn.close()^
    ^
    items = []^
    for row in rows:^
        item = dict(row)^
        item['tags'] = json.loads(item['tags']) if item['tags'] else []^
        items.append(item)^
    ^
    return jsonify({^
        'success': True,^
        'data': {^
            'items': items,^
            'pagination': {^
                'page': page,^
                'pageSize': page_size,^
                'total': total,^
                'totalPages': (total + page_size - 1) // page_size^
            }^
        }^
    })^
^
@app.route('/api/channels')^
def get_channels():^
    conn = get_db()^
    c = conn.cursor()^
    c.execute('SELECT source as id, source as name, COUNT(*) as count FROM articles GROUP BY source ORDER BY count DESC')^
    channels = [dict(row) for row in c.fetchall()]^
    conn.close()^
    return jsonify({'success': True, 'data': channels})^
^
if __name__ == '__main__':^
    print('[Backend] API服务启动于 http://localhost:3001')^
    app.run(port=3001, host='0.0.0.0')"
echo.

echo [启动前端...]
cd ..\frontend
start "AI-News-Frontend" cmd /k "npm run dev"
cd ..\backend
echo.
echo ========================================
echo   服务已启动
echo   后端API: http://localhost:3001
echo   前端网站: http://localhost:3000
echo ========================================
echo.
goto menu

:start_backend
echo [启动后端API...]
start "AI-News-Backend" cmd /k "python -c ^
from flask import Flask, jsonify, request^
from flask_cors import CORS^
import sqlite3^
import json^
^
app = Flask(__name__)^
CORS(app)^
^
def get_db():^
    conn = sqlite3.connect('news.db')^
    conn.row_factory = sqlite3.Row^
    return conn^
^
@app.route('/api/news')^
def get_news():^
    page = int(request.args.get('page', 1))^
    page_size = int(request.args.get('pageSize', 12))^
    channel = request.args.get('channel', 'all')^
    keyword = request.args.get('keyword', '')^
    ^
    conn = get_db()^
    c = conn.cursor()^
    ^
    sql = 'SELECT * FROM articles WHERE 1=1'^
    params = []^
    ^
    if channel != 'all':^
        sql += ' AND source = ?'^
        params.append(channel)^
    ^
    if keyword:^
        sql += ' AND (title LIKE ? OR summary LIKE ?)'^
        params.extend([f'%{keyword}%', f'%{keyword}%'])^
    ^
    sql += ' ORDER BY score DESC, published_at DESC'^
    offset = (page - 1) * page_size^
    sql += f' LIMIT {page_size} OFFSET {offset}'^
    ^
    c.execute(sql, params)^
    rows = c.fetchall()^
    ^
    count_sql = 'SELECT COUNT(*) FROM articles WHERE 1=1' + (' AND source = ?' if channel != 'all' else '')^
    c.execute(count_sql, params[:1] if channel != 'all' else [])^
    total = c.fetchone()[0]^
    conn.close()^
    ^
    items = []^
    for row in rows:^
        item = dict(row)^
        item['tags'] = json.loads(item['tags']) if item['tags'] else []^
        items.append(item)^
    ^
    return jsonify({^
        'success': True,^
        'data': {^
            'items': items,^
            'pagination': {^
                'page': page,^
                'pageSize': page_size,^
                'total': total,^
                'totalPages': (total + page_size - 1) // page_size^
            }^
        }^
    })^
^
@app.route('/api/channels')^
def get_channels():^
    conn = get_db()^
    c = conn.cursor()^
    c.execute('SELECT source as id, source as name, COUNT(*) as count FROM articles GROUP BY source ORDER BY count DESC')^
    channels = [dict(row) for row in c.fetchall()]^
    conn.close()^
    return jsonify({'success': True, 'data': channels})^
^
if __name__ == '__main__':^
    print('[Backend] API服务启动于 http://localhost:3001')^
    app.run(port=3001, host='0.0.0.0')"
echo [后端已启动，地址: http://localhost:3001]
goto menu

:start_frontend
echo [启动前端...请确保后端已启动]
cd ..\frontend
start "AI-News-Frontend" cmd /k "npm run dev"
cd ..\backend
echo [前端已启动，地址: http://localhost:3000]
goto menu

:stop_all
echo [停止所有服务...]
taskkill /F /IM node.exe 2>nul
taskkill /F /IM python.exe 2>nul
echo [所有服务已停止]
goto menu

:collect
echo [运行数据采集...]
python collector.py collect
echo.
echo [采集完成]
pause
goto menu

:status
echo [检查服务状态...]
netstat -an | findstr "3000"
netstat -an | findstr "3001"
goto menu

:end
echo [退出]
