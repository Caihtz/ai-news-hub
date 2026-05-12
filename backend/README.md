# AI News Hub - 稳定运行指南

## 快速启动

### 方式一: 使用管理脚本 (推荐)
```batch
cd F:\Claude code项目\新闻\新闻\backend
run.bat
```

### 方式二: 手动启动
```batch
# 终端1: 启动后端API
cd F:\Claude code项目\新闻\新闻\backend
python -c "from flask import Flask, jsonify, request; from flask_cors import CORS; ..." (使用collector.py中的API代码)

# 终端2: 启动前端
cd F:\Claude code项目\新闻\新闻\frontend
npm run dev
```

---

## 定时任务设置

### Windows 定时任务 (每小时自动采集)

1. **打开命令提示符 (管理员)**
   ```
   右键开始菜单 → 命令提示符 (管理员)
   ```

2. **创建定时任务**
   ```batch
   cd F:\Claude code项目\新闻\新闻\backend
   setup_scheduler.bat
   ```

3. **或手动创建**
   ```batch
   schtasks /create /tn "AINewsCollector" /tr "F:\Claude code项目\新闻\新闻\backend\scheduler_task.bat" /sc HOURLY /st 00:05 /f
   ```

4. **管理任务**
   ```batch
   schtasks /query /tn "AINewsCollector"   # 查看状态
   schtasks /run /tn "AINewsCollector"      # 立即执行
   schtasks /delete /tn "AINewsCollector"  # 删除任务
   ```

### Linux/Mac 定时任务

```bash
# 编辑crontab
crontab -e

# 添加以下行 (每小时执行一次)
5 * * * * cd /path/to/news/backend && python3 collector.py collect >> /var/log/ai-news.log 2>&1
```

---

## 健康检查

### 检查服务状态
```batch
cd F:\Claude code项目\新闻\新闻\backend
health_check.bat
```

### 手动检查
```bash
# 检查后端API
curl http://localhost:3001/api/stats

# 检查前端
curl http://localhost:3000

# 查看数据库
python -c "import sqlite3; conn=sqlite3.connect('news.db'); print(conn.execute('SELECT COUNT(*) FROM articles').fetchone()[0])"
```

---

## 数据管理

### 手动采集数据
```batch
cd F:\Claude code项目\新闻\新闻\backend
python collector.py collect
```

### 清理过期数据 (自动执行)
- 默认保留7天数据
- 每次采集前自动清理
- 可修改 `collector.py` 中的 `cleanup_old_articles(days=7)`

### 数据库位置
```
F:\Claude code项目\新闻\新闻\backend\news.db
```

---

## 开机自启设置 (Windows)

### 方法1: 启动文件夹
1. 按 `Win + R`，输入 `shell:startup`
2. 创建快捷方式指向:
   - `run.bat` (完整启动)

### 方法2: 任务计划程序
```batch
schtasks /create /tn "AI News Hub" /tr "F:\Claude code项目\新闻\新闻\backend\run.bat" /sc ONLOGON /f
```

---

## 常见问题

### Q: 服务无法启动
A: 检查端口占用
```batch
netstat -ano | findstr "3000"
netstat -ano | findstr "3001"
```

### Q: 采集失败
A: 检查网络连接和RSS源状态

### Q: 数据库过大
A: 手动执行VACUUM
```python
import sqlite3
conn = sqlite3.connect('news.db')
conn.execute('VACUUM')
conn.close()
```

---

## 服务地址

| 服务 | 地址 | 说明 |
|------|------|------|
| 前端网站 | http://localhost:3000 | Next.js 开发服务器 |
| 后端API | http://localhost:3001 | Flask API |
| API文档 | http://localhost:3001/api/stats | 数据库统计 |

---

## 文件说明

```
backend/
├── collector.py         # 数据采集器 (含清理逻辑)
├── news.db             # SQLite数据库
├── run.bat             # 服务管理脚本
├── scheduler_task.bat   # 定时任务执行脚本
├── setup_scheduler.bat  # 定时任务安装脚本
├── health_check.bat    # 健康检查脚本
├── crontab_example.txt # Linux定时任务配置示例
└── README.md           # 本文件
```
