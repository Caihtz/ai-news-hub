#!/bin/bash
# ============================================
# 阿里云 ECS CentOS 服务器初始化脚本
# 首次部署时运行一次即可
# ============================================
set -e

echo "=========================================="
echo " AI资讯中心 - 服务器初始化"
echo "=========================================="

# ---- 检测 CentOS 版本 ----
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_VERSION=$VERSION_ID
else
    echo "无法检测系统版本"
    exit 1
fi
echo "检测到: $NAME $OS_VERSION"

# ---- 配置防火墙 ----
echo ""
echo "[1/6] 配置防火墙..."
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-service=http 2>/dev/null || true
    sudo firewall-cmd --permanent --add-service=https 2>/dev/null || true
    sudo firewall-cmd --permanent --add-port=3000/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --add-port=3001/tcp 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    echo "防火墙已配置"
else
    echo "firewalld 未启用，跳过"
fi

# ---- 安装基础依赖 ----
echo ""
echo "[2/6] 安装基础工具..."
sudo yum install -y epel-release 2>/dev/null || true
sudo yum install -y curl wget git unzip

# ---- 安装 Node.js 18 ----
echo ""
echo "[3/6] 安装 Node.js 18..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
    echo "Node.js $(node -v) 安装完成"
else
    echo "Node.js $(node -v) 已安装"
fi

# ---- 安装 Python 3 ----
echo ""
echo "[4/6] 安装 Python 3..."
if ! command -v python3 &> /dev/null; then
    sudo yum install -y python3 python3-pip python3-devel
    echo "Python $(python3 -V) 安装完成"
else
    echo "Python $(python3 -V) 已安装"
fi

# ---- 安装 Nginx ----
echo ""
echo "[5/6] 安装 Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo yum install -y nginx
    sudo systemctl enable nginx
    echo "Nginx 安装完成"
else
    echo "Nginx 已安装"
fi

# ---- 安装 PM2 ----
echo ""
echo "[6/6] 安装 PM2..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
    echo "PM2 安装完成"
else
    echo "PM2 已安装"
fi

# ---- 创建部署目录 ----
echo ""
echo "创建部署目录..."
sudo mkdir -p /var/www/avenchoi.top
sudo chown -R $USER:$USER /var/www/avenchoi.top

# ---- 配置 Nginx ----
echo ""
echo "复制 Nginx 配置..."
sudo cp /var/www/avenchoi.top/deploy/nginx.conf /etc/nginx/conf.d/avenchoi.top.conf

# 测试 Nginx 配置
sudo nginx -t

# ---- 安装 Python 依赖 ----
echo ""
echo "安装 Python 依赖..."
cd /var/www/avenchoi.top/backend
pip3 install -r requirements.txt

# ---- 构建前端 ----
echo ""
echo "构建前端..."
cd /var/www/avenchoi.top/frontend
npm install
npm run build

echo ""
echo "=========================================="
echo " 初始化完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 上传项目文件到 /var/www/avenchoi.top/"
echo "2. 运行: sudo systemctl start nginx"
echo "3. 启动服务: cd /var/www/avenchoi.top && pm2 start ecosystem.config.js"
echo "4. 保存 PM2 进程: pm2 save && pm2 startup"
echo ""
