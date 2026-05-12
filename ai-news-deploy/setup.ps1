# ============================================
# AI资讯中心 - 一键部署脚本 (Windows Server)
# 以管理员身份在 PowerShell 中运行
# ============================================
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  AI资讯中心 - 一键部署到 avnechoi.top" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

$ProjectDir = "C:\www\avenchoi.top"
$NginxDir = "C:\nginx"

# ====== 1. 创建目录 ======
Write-Host "`n[1/8] 创建目录..." -ForegroundColor Yellow
$dirs = @("$ProjectDir", "$NginxDir\conf\conf.d", "$NginxDir\logs", "$NginxDir\ssl")
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

# ====== 2. 防火墙 ======
Write-Host "[2/8] 配置防火墙..." -ForegroundColor Yellow
@(80, 443) | ForEach-Object {
    New-NetFirewallRule -DisplayName "Web-$_" -Direction Inbound -Protocol TCP -LocalPort $_ -Action Allow -Profile Any 2>$null
}

# ====== 3. Node.js ======
Write-Host "[3/8] 安装 Node.js..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "  下载中..."
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v18.20.4/node-v18.20.4-win-x64.zip" -OutFile "$env:TEMP\nodejs.zip"
    Expand-Archive -Path "$env:TEMP\nodejs.zip" -DestinationPath "C:\nodejs" -Force
    [Environment]::SetEnvironmentVariable("Path", "C:\nodejs;" + [Environment]::GetEnvironmentVariable("Path", "Machine"), "Machine")
    $env:Path = "C:\nodejs;" + $env:Path
}
Write-Host "  Node.js: $(node -v)" -ForegroundColor Green

# ====== 4. Python ======
Write-Host "[4/8] 安装 Python..." -ForegroundColor Yellow
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "  下载中..."
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe" -OutFile "$env:TEMP\python-installer.exe"
    Start-Process -Wait -FilePath "$env:TEMP\python-installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1"
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine")
}
Write-Host "  Python: $(python --version)" -ForegroundColor Green

# ====== 5. Nginx ======
Write-Host "[5/8] 安装 Nginx..." -ForegroundColor Yellow
if (-not (Test-Path "$NginxDir\nginx.exe")) {
    Write-Host "  下载中..."
    Invoke-WebRequest -Uri "https://nginx.org/download/nginx-1.26.2.zip" -OutFile "$env:TEMP\nginx.zip"
    $extractDir = "$env:TEMP\nginx-extract"
    Expand-Archive -Path "$env:TEMP\nginx.zip" -DestinationPath $extractDir -Force
    $nginxSrc = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    Copy-Item -Path "$($nginxSrc.FullName)\*" -Destination $NginxDir -Recurse -Force
    Remove-Item $extractDir -Recurse -Force
}
Write-Host "  Nginx 就绪" -ForegroundColor Green

# ====== 6. PM2 ======
Write-Host "[6/8] 安装 PM2..." -ForegroundColor Yellow
if (-not (Get-Command pm2 -ErrorAction SilentlyContinue)) {
    npm install -g pm2
}
Write-Host "  PM2 就绪" -ForegroundColor Green

# ====== 7. 安装项目依赖 ======
Write-Host "[7/8] 安装项目依赖..." -ForegroundColor Yellow

Write-Host "  安装 Python 依赖..."
Set-Location "$ProjectDir\backend"
pip install -r requirements.txt --quiet 2>&1 | Out-Null
Write-Host "  Python 依赖安装完成" -ForegroundColor Green

Write-Host "  安装前端依赖并构建..."
Set-Location "$ProjectDir\frontend"
npm install --silent 2>&1 | Out-Null
Write-Host "  构建前端 (约1-2分钟)..."
npm run build 2>&1 | Out-Null
Write-Host "  前端构建完成" -ForegroundColor Green

# ====== 8. 配置并启动 Nginx ======
Write-Host "[8/8] 配置并启动服务..." -ForegroundColor Yellow

# 复制 Nginx 站点配置
Copy-Item -Path "$ProjectDir\deploy\nginx-win.conf" -Destination "$NginxDir\conf\conf.d\avenchoi.top.conf" -Force

# 确保主配置 include conf.d
$mainConf = "$NginxDir\conf\nginx.conf"
$content = Get-Content $mainConf -Raw
if ($content -notmatch "include conf.d") {
    $content = $content -replace '(http\s*\{[^}]*?)\}', "`$1`n    include conf.d/*.conf;`n}"
    $content | Out-File -FilePath $mainConf -Encoding ASCII
}

# 测试 Nginx 配置
& "$NginxDir\nginx.exe" -t

# 停止已有进程
Get-Process nginx -ErrorAction SilentlyContinue | Stop-Process -Force
pm2 delete all 2>$null

# 启动 Nginx
Start-Process "$NginxDir\nginx.exe" -WindowStyle Hidden
Write-Host "  Nginx 已启动" -ForegroundColor Green

# 采集新闻数据
Write-Host "  采集新闻数据..."
Set-Location "$ProjectDir\backend"
python collector.py collect

# 启动 PM2 管理前后端
Set-Location $ProjectDir
pm2 start ecosystem.config.js
pm2 save
pm2 startup | Invoke-Expression 2>$null

Write-Host "`n==============================================" -ForegroundColor Green
Write-Host "  部署完成!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  访问: http://avenchoi.top"
Write-Host "  API:  http://avenchoi.top/api/news"
Write-Host ""
Write-Host "  管理命令:"
Write-Host "    pm2 status    查看状态"
Write-Host "    pm2 logs      查看日志"
Write-Host "    pm2 restart all  重启服务"
Write-Host ""
Write-Host "  定时采集 (每小时):"
Write-Host "    cd C:\www\avenchoi.top\backend"
Write-Host "    python collector.py collect"
Write-Host ""
