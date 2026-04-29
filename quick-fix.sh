#!/bin/bash

# ========================================
# 快速修复脚本 - 解决无法访问的问题
# ========================================
# 针对 http://116.205.173.60:8080/ 无法访问的问题
# 用法: ./quick-fix.sh

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=======================================${NC}"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

# 应用配置
APP_HOME="/ray_tool/custom-function-processor"
JAR_FILE="$APP_HOME/custom-function-processor-0.0.1-SNAPSHOT.jar"
SERVER_IP="116.205.173.60"
PORT=8080

fix_firewall() {
    print_header "1. 修复防火墙设置"

    # 检查操作系统类型
    if [ -f /etc/redhat-release ]; then
        # CentOS/RHEL
        print_info "检测到 CentOS/RHEL 系统"

        if command -v firewall-cmd &>/dev/null; then
            print_info "配置firewalld..."
            sudo firewall-cmd --permanent --add-port=${PORT}/tcp
            sudo firewall-cmd --reload
            print_success "firewalld配置完成"
        else
            print_info "配置iptables..."
            sudo iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
            sudo service iptables save
            print_success "iptables配置完成"
        fi
    elif [ -f /etc/debian_version ]; then
        # Ubuntu/Debian
        print_info "检测到 Ubuntu/Debian 系统"

        if command -v ufw &>/dev/null; then
            print_info "配置ufw..."
            sudo ufw allow ${PORT}
            print_success "ufw配置完成"
        else
            print_info "配置iptables..."
            sudo iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
            print_success "iptables配置完成"
        fi
    else
        print_warning "未识别的操作系统，请手动配置防火墙"
    fi
    echo ""
}

restart_application() {
    print_header "2. 重启应用"

    cd "$APP_HOME"

    # 停止现有应用
    print_info "停止现有应用..."
    ./linux-deploy.sh stop 2>/dev/null || print_warning "应用可能未在运行"

    sleep 2

    # 启动应用
    print_info "启动应用..."
    ./linux-deploy.sh start

    echo ""
}

verify_fix() {
    print_header "3. 验证修复结果"

    # 等待应用完全启动
    print_info "等待应用启动..."
    sleep 5

    # 检查端口监听
    if netstat -tlnp 2>/dev/null | grep ":${PORT} " | grep LISTEN; then
        print_success "端口 ${PORT} 正在监听"
    else
        print_error "端口 ${PORT} 未被监听"
        return 1
    fi

    # 测试本地访问
    if curl -s --max-time 10 http://localhost:${PORT} > /dev/null; then
        print_success "本地访问正常"
    else
        print_error "本地访问失败"
        return 1
    fi

    # 测试外部访问
    if curl -s --max-time 10 http://${SERVER_IP}:${PORT} > /dev/null; then
        print_success "外部访问正常 - 问题已解决!"
        print_success "访问地址: http://${SERVER_IP}:${PORT}/"
    else
        print_warning "外部访问仍有问题，可能需要进一步检查"
        print_info "可能的原因:"
        echo "  - 网络配置问题"
        echo "  - 服务器安全组设置"
        echo "  - DNS解析问题"
    fi

    echo ""
}

show_status() {
    print_header "4. 当前状态信息"

    print_info "应用状态:"
    ./linux-deploy.sh status

    echo ""
    print_info "网络状态:"
    echo "服务器IP: ${SERVER_IP}"
    echo "端口: ${PORT}"
    echo "访问地址: http://${SERVER_IP}:${PORT}/"

    echo ""
    print_info "测试命令:"
    echo "curl http://localhost:${PORT}"
    echo "curl http://${SERVER_IP}:${PORT}"

    echo ""
    print_success "修复脚本执行完成!"
    print_info "如果仍然无法访问，请运行网络诊断脚本:"
    echo "./network-diagnostic.sh"
}

main() {
    print_header "快速修复工具"
    print_info "解决 http://${SERVER_IP}:${PORT}/ 无法访问的问题"
    echo ""

    # 检查是否在正确的目录
    if [ ! -f "$APP_HOME/linux-deploy.sh" ]; then
        print_error "未找到部署脚本，请确保在正确的目录运行"
        print_info "期望位置: $APP_HOME/linux-deploy.sh"
        exit 1
    fi

    # 修复防火墙
    fix_firewall

    # 重启应用
    restart_application

    # 验证修复
    if verify_fix; then
        print_success "修复成功!"
    else
        print_error "修复可能未完全成功，请检查日志"
    fi

    # 显示状态
    show_status
}

# 运行主函数
main "$@"
