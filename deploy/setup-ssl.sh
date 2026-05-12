#!/bin/bash
# ============================================
# SSL 证书配置 (ECS 上执行)
# 方式一: Let's Encrypt 免费证书 (推荐)
# 方式二: 阿里云免费 SSL 证书
# ============================================
set -e

DOMAIN="avenchoi.top"

echo "=========================================="
echo " SSL 证书配置 - $DOMAIN"
echo "=========================================="
echo ""
echo "请选择 SSL 证书方式:"
echo "  1) Let's Encrypt (certbot, 自动续期)"
echo "  2) 阿里云免费 SSL (需在控制台下载后手动上传)"
echo ""
read -p "请输入 [1/2]: " CHOICE

if [ "$CHOICE" = "1" ]; then
    echo ""
    echo "--- 安装 Certbot ---"
    # CentOS 7
    if [ -f /etc/centos-release ]; then
        CENTOS_VER=$(rpm -E %{rhel})
        if [ "$CENTOS_VER" -eq 7 ]; then
            sudo yum install -y certbot python2-certbot-nginx
        else
            sudo dnf install -y certbot python3-certbot-nginx
        fi
    fi

    echo ""
    echo "--- 获取证书 ---"
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN

    echo ""
    echo "--- 配置自动续期 ---"
    # 添加 daily cron job
    echo "0 3 * * * root certbot renew --quiet --post-hook 'systemctl reload nginx'" | sudo tee /etc/cron.d/certbot-renew

    # 测试自动续期
    sudo certbot renew --dry-run

    echo "SSL 证书配置完成！"

elif [ "$CHOICE" = "2" ]; then
    echo ""
    echo "=== 阿里云免费 SSL 证书配置 ==="
    echo ""
    echo "步骤:"
    echo "1. 登录阿里云控制台 → SSL 证书 → 免费证书 → 立即购买"
    echo "2. 创建证书，填写域名: $DOMAIN"
    echo "3. DNS 验证（自动添加记录）"
    echo "4. 下载 Nginx 格式证书"
    echo ""
    echo "下载后将 .pem 和 .key 文件上传到服务器:"
    echo "  scp cert.pem root@<IP>:/etc/nginx/ssl/$DOMAIN.pem"
    echo "  scp cert.key root@<IP>:/etc/nginx/ssl/$DOMAIN.key"
    echo ""
    echo "然后执行以下命令更新 Nginx:"
    echo "  sudo mkdir -p /etc/nginx/ssl"
    echo "  sudo nginx -t && sudo systemctl reload nginx"
    echo ""
    echo "最后编辑 /etc/nginx/conf.d/avenchoi.top.conf"
    echo "取消 HTTPS server 块的注释并重启 Nginx"
fi
