#!/bin/bash
# ============================================
# 本地执行：构建前端 + 上传到 ECS + 重启服务
# 用法: bash deploy/upload-and-deploy.sh <ECS_IP>
# 示例: bash deploy/upload-and-deploy.sh 47.96.xxx.xxx
# ============================================
set -e

if [ -z "$1" ]; then
    echo "用法: bash deploy/upload-and-deploy.sh <ECS_IP>"
    echo "示例: bash deploy/upload-and-deploy.sh 47.96.xxx.xxx"
    exit 1
fi

ECS_IP="$1"
ECS_USER="root"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=========================================="
echo " AI资讯中心 - 部署到阿里云 ECS"
echo " 目标服务器: $ECS_IP"
echo "=========================================="

# ---- 构建前端 ----
echo ""
echo "[1/4] 构建前端..."
cd "$PROJECT_DIR/frontend"
npm install --silent
npm run build
echo "前端构建完成"

# ---- 上传项目文件 ----
echo ""
echo "[2/4] 上传项目文件到服务器..."
cd "$PROJECT_DIR"

# 需要上传的目录/文件
ssh $ECS_USER@$ECS_IP "mkdir -p /var/www/avenchoi.top"

# 上传前端 (排除 node_modules 中的开发依赖)
rsync -avz --progress \
    --exclude='node_modules' \
    --exclude='.next/cache' \
    frontend/ $ECS_USER@$ECS_IP:/var/www/avenchoi.top/frontend/

# 上传后端
rsync -avz --progress \
    --exclude='__pycache__' \
    --exclude='news.db' \
    --exclude='node_modules' \
    backend/ $ECS_USER@$ECS_IP:/var/www/avenchoi.top/backend/

# 上传 PM2 配置和部署脚本
scp ecosystem.config.js $ECS_USER@$ECS_IP:/var/www/avenchoi.top/
scp -r deploy/ $ECS_USER@$ECS_IP:/var/www/avenchoi.top/

echo "文件上传完成"

# ---- 服务器端安装依赖 ----
echo ""
echo "[3/4] 服务器安装依赖..."
ssh $ECS_USER@$ECS_IP << 'ENDSSH'
cd /var/www/avenchoi.top

# 安装前端依赖
cd frontend
npm install --production
cd ..

# 安装后端依赖
cd backend
pip3 install -r requirements.txt
cd ..

echo "依赖安装完成"
ENDSSH

# ---- 配置 Nginx 并重启服务 ----
echo ""
echo "[4/4] 配置 Nginx 并重启服务..."
ssh $ECS_USER@$ECS_IP << 'ENDSSH'
# Nginx 配置
sudo cp /var/www/avenchoi.top/deploy/nginx.conf /etc/nginx/conf.d/avenchoi.top.conf
sudo nginx -t && sudo systemctl reload nginx

# PM2 重启
cd /var/www/avenchoi.top
pm2 reload ecosystem.config.js || pm2 start ecosystem.config.js
pm2 save

echo ""
echo "=========================================="
echo " 部署完成！"
echo "=========================================="
echo ""
echo "访问地址: http://avenchoi.top"
echo "API 地址: http://avenchoi.top/api/news"
echo ""
echo "查看服务状态: pm2 status"
echo "查看日志: pm2 logs"
ENDSSH
