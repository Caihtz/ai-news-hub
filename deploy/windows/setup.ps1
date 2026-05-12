# ============================================
# AI资讯中心 - Windows Server 初始化脚本
# 以管理员身份在 PowerShell 中运行
# ============================================
$ErrorActionPreference = "Stop"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " AI资讯中心 - Windows Server 部署" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$ProjectDir = "C:\www\avenchoi.top"
$NginxDir = "C:\nginx"

# ---- 1. 创建目录 ----
Write-Host "`n[1/6] 创建目录..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $ProjectDir | Out-Null
New-Item -ItemType Directory -Force -Path "$NginxDir\conf\conf.d" | Out-Null
New-Item -ItemType Directory -Force -Path "$NginxDir\logs" | Out-Null
New-Item -ItemType Directory -Force -Path "$NginxDir\ssl" | Out-Null

# ---- 2. 配置防火墙 ----
Write-Host "`n[2/6] 配置防火墙..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "HTTP 80" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -Profile Any 2>$null
New-NetFirewallRule -DisplayName "HTTPS 443" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -Profile Any 2>$null
New-NetFirewallRule -DisplayName "Frontend 3000" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -Profile Any 2>$null
New-NetFirewallRule -DisplayName "Backend 3001" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow -Profile Any 2>$null
Write-Host "防火墙规则已添加"

# ---- 3. 安装 Node.js (如果未安装) ----
Write-Host "`n[3/6] 检查 Node.js..." -ForegroundColor Yellow
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeInstalled) {
    Write-Host "正在下载 Node.js..."
    $nodeUrl = "https://nodejs.org/dist/v18.20.4/node-v18.20.4-win-x64.zip"
    Invoke-WebRequest -Uri $nodeUrl -OutFile "$env:TEMP\nodejs.zip"
    Expand-Archive -Path "$env:TEMP\nodejs.zip" -DestinationPath "C:\nodejs" -Force

    [Environment]::SetEnvironmentVariable("Path", "C:\nodejs;" + [Environment]::GetEnvironmentVariable("Path", "Machine"), "Machine")
    $env:Path = "C:\nodejs;" + $env:Path
    Write-Host "Node.js 安装完成"
} else {
    Write-Host "Node.js 已安装: $(node -v)"
}

# ---- 4. 安装 Python (如果未安装) ----
Write-Host "`n[4/6] 检查 Python..." -ForegroundColor Yellow
$pythonInstalled = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonInstalled) {
    Write-Host "正在下载 Python..."
    $pyUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
    Invoke-WebRequest -Uri $pyUrl -OutFile "$env:TEMP\python-installer.exe"
    Start-Process -Wait -FilePath "$env:TEMP\python-installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1"
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine")
    Write-Host "Python 安装完成"
} else {
    Write-Host "Python 已安装: $(python -V)"
}

# ---- 5. 安装 Nginx ----
Write-Host "`n[5/6] 安装 Nginx..." -ForegroundColor Yellow
$nginxExe = "$NginxDir\nginx.exe"
if (-not (Test-Path $nginxExe)) {
    Write-Host "正在下载 Nginx..."
    $nginxUrl = "https://nginx.org/download/nginx-1.26.2.zip"
    Invoke-WebRequest -Uri $nginxUrl -OutFile "$env:TEMP\nginx.zip"

    # 解压到临时目录
    Expand-Archive -Path "$env:TEMP\nginx.zip" -DestinationPath "$env:TEMP\nginx-extract" -Force
    # 复制到 C:\nginx
    Copy-Item -Path "$env:TEMP\nginx-extract\nginx-*\*" -Destination $NginxDir -Recurse -Force
    Write-Host "Nginx 安装完成"
} else {
    Write-Host "Nginx 已安装"
}

# ---- 6. 安装 PM2 ----
Write-Host "`n[6/6] 安装 PM2..." -ForegroundColor Yellow
$pm2Installed = Get-Command pm2 -ErrorAction SilentlyContinue
if (-not $pm2Installed) {
    npm install -g pm2
    Write-Host "PM2 安装完成"
} else {
    Write-Host "PM2 已安装"
}

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host " 初始化完成！下一步:" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "1. 将项目文件复制到 C:\www\avenchoi.top\"
Write-Host "2. 运行 deploy.ps1 完成部署"
Write-Host ""
