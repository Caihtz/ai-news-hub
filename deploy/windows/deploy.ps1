# ============================================
# AI资讯中心 - 部署脚本
# 将项目文件复制到 C:\www\avenchoi.top 后运行
# ============================================
$ErrorActionPreference = "Stop"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " AI资讯中心 - 部署" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$ProjectDir = "C:\www\avenchoi.top"
$NginxDir = "C:\nginx"

Set-Location $ProjectDir

# ---- 1. 安装 Python 依赖 ----
Write-Host "`n[1/4] 安装 Python 依赖..." -ForegroundColor Yellow
Set-Location "$ProjectDir\backend"
pip install -r requirements.txt
Write-Host "Python 依赖安装完成"

# ---- 2. 安装前端依赖并构建 ----
Write-Host "`n[2/4] 构建前端..." -ForegroundColor Yellow
Set-Location "$ProjectDir\frontend"
npm install
npm run build
Write-Host "前端构建完成"

# ---- 3. 配置 Nginx ----
Write-Host "`n[3/4] 配置 Nginx..." -ForegroundColor Yellow
# 复制站点配置
Copy-Item -Path "$ProjectDir\deploy\nginx-win.conf" -Destination "$NginxDir\conf\conf.d\avenchoi.top.conf" -Force

# 确保主配置 include conf.d
$mainConf = "$NginxDir\conf\nginx.conf"
if (Select-String -Path $mainConf -Pattern "include conf.d" -Quiet) {
    Write-Host "Nginx 已包含 conf.d 目录"
} else {
    Add-Content -Path $mainConf -Value "`n    include conf.d/*.conf;`n"
    Write-Host "Nginx 主配置已更新"
}

# 测试 Nginx 配置
& "$NginxDir\nginx.exe" -t
Write-Host "Nginx 配置完成"

# ---- 4. 启动服务 ----
Write-Host "`n[4/4] 启动服务..." -ForegroundColor Yellow

# 停止已有 PM2 进程
pm2 delete all 2>$null

# 启动 Nginx
$nginxProc = Get-Process nginx -ErrorAction SilentlyContinue
if (-not $nginxProc) {
    Start-Process "$NginxDir\nginx.exe" -WindowStyle Hidden
    Write-Host "Nginx 已启动"
} else {
    & "$NginxDir\nginx.exe" -s reload
    Write-Host "Nginx 已重载"
}

# 使用 PM2 启动前后端
pm2 start "$ProjectDir\ecosystem.config.js"
pm2 save

# 设置 PM2 开机自启
pm2 startup | Invoke-Expression

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host " 部署完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "访问: http://avenchoi.top"
Write-Host "API:  http://avenchoi.top/api/news"
Write-Host ""
Write-Host "管理命令:"
Write-Host "  pm2 status         查看服务状态"
Write-Host "  pm2 logs           查看日志"
Write-Host "  pm2 restart all    重启所有服务"
Write-Host ""
