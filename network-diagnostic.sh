#!/bin/bash

# ========================================
# 网络连接诊断脚本
# ========================================
# 用于诊断为什么无法访问 http://116.205.173.60:8080/
# 用法: ./network-diagnostic.sh

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

check_network_connectivity() {
    print_header "1. 网络连接检查"

    # 检查基本网络连接
    if ping -c 1 8.8.8.8 &>/dev/null; then
        print_success "互联网连接正常"
    else
        print_error "互联网连接异常"
    fi

    # 检查本机网络接口
    print_info "网络接口信息:"
    ip addr show | grep -E "(inet|state)" | head -10
    echo ""
}

check_port_binding() {
    print_header "2. 应用端口绑定检查"

    local port=8080

    # 检查端口监听
    if netstat -tlnp 2>/dev/null | grep ":$port " | grep LISTEN; then
        print_success "端口 $port 正在监听"
        print_info "监听详情:"
        netstat -tlnp | grep ":$port " | grep LISTEN
    else
        print_error "端口 $port 未被监听"
        print_warning "应用可能未正确启动或绑定到其他地址"
    fi
    echo ""

    # 检查应用进程
    print_info "Java进程检查:"
    if ps aux | grep java | grep -v grep; then
        print_success "发现Java进程"
        ps aux | grep java | grep -v grep
    else
        print_error "未发现Java进程"
    fi
    echo ""
}

check_firewall() {
    print_header "3. 防火墙检查"

    # 检查firewalld
    if command -v firewall-cmd &>/dev/null; then
        print_info "firewalld状态:"
        sudo firewall-cmd --state 2>/dev/null || print_warning "无法获取firewalld状态"

        print_info "防火墙规则:"
        sudo firewall-cmd --list-all 2>/dev/null | grep 8080 || print_info "端口8080规则未找到"
    fi

    # 检查ufw
    if command -v ufw &>/dev/null; then
        print_info "ufw状态:"
        sudo ufw status | grep 8080 || print_info "端口8080规则未找到"
    fi

    # 检查iptables
    if command -v iptables &>/dev/null; then
        print_info "iptables规则:"
        sudo iptables -L -n | grep :8080 || print_info "端口8080规则未找到"
    fi
    echo ""
}

check_application_status() {
    print_header "4. 应用状态检查"

    local app_home="/ray_tool/custom-function-processor"
    local jar_file="$app_home/custom-function-processor-0.0.1-SNAPSHOT.jar"
    local pid_file="$app_home/app.pid"
    local log_file="$app_home/logs/app.log"

    # 检查部署目录
    if [ -d "$app_home" ]; then
        print_success "部署目录存在: $app_home"
    else
        print_error "部署目录不存在: $app_home"
    fi

    # 检查JAR文件
    if [ -f "$jar_file" ]; then
        print_success "JAR文件存在: $(basename $jar_file)"
    else
        print_error "JAR文件不存在: $jar_file"
    fi

    # 检查PID文件
    if [ -f "$pid_file" ]; then
        local pid=$(cat $pid_file 2>/dev/null)
        if ps -p $pid > /dev/null 2>&1; then
            print_success "应用正在运行 (PID: $pid)"
        else
            print_error "PID文件存在但进程不存在 (PID: $pid)"
        fi
    else
        print_warning "PID文件不存在，应用可能未启动"
    fi

    # 检查日志文件
    if [ -f "$log_file" ]; then
        print_info "最近的日志内容:"
        tail -10 "$log_file"
    else
        print_warning "日志文件不存在: $log_file"
    fi
    echo ""
}

check_external_access() {
    print_header "5. 外部访问检查"

    local server_ip="116.205.173.60"
    local port=8080

    print_info "测试外部访问..."

    # 测试本地访问
    if curl -s --max-time 5 http://localhost:$port > /dev/null; then
        print_success "本地访问正常 (localhost:$port)"
    else
        print_error "本地访问失败 (localhost:$port)"
    fi

    # 测试服务器IP访问
    if curl -s --max-time 5 http://$server_ip:$port > /dev/null; then
        print_success "服务器IP访问正常 ($server_ip:$port)"
    else
        print_error "服务器IP访问失败 ($server_ip:$port)"
        print_warning "这可能是防火墙、端口绑定或网络配置问题"
    fi

    # 测试0.0.0.0绑定
    if curl -s --max-time 5 http://0.0.0.0:$port > /dev/null; then
        print_success "0.0.0.0绑定访问正常"
    else
        print_error "0.0.0.0绑定访问失败"
    fi
    echo ""
}

provide_solutions() {
    print_header "6. 解决方案建议"

    print_info "根据诊断结果，以下是可能的解决方案:"

    echo ""
    print_warning "1. 如果端口未被监听:"
    echo "   - 检查应用是否正确启动"
    echo "   - 查看应用日志: ./linux-deploy.sh logs"
    echo "   - 重启应用: ./linux-deploy.sh restart"

    echo ""
    print_warning "2. 如果是防火墙问题:"
    echo "   - CentOS/RHEL: sudo firewall-cmd --permanent --add-port=8080/tcp && sudo firewall-cmd --reload"
    echo "   - Ubuntu/Debian: sudo ufw allow 8080"

    echo ""
    print_warning "3. 如果应用绑定到localhost:"
    echo "   - 确保JVM参数包含: -Dserver.address=0.0.0.0"
    echo "   - 重启应用以应用新配置"

    echo ""
    print_warning "4. 检查网络配置:"
    echo "   - 确认服务器IP地址正确"
    echo "   - 检查网络接口配置: ip addr show"
    echo "   - 测试端口连通性: telnet $server_ip 8080"

    echo ""
    print_success "快速修复命令:"
    echo "   # 重新上传并重启应用"
    echo "   ./linux-deploy.sh stop"
    echo "   ./linux-deploy.sh start"
    echo ""
    echo "   # 检查端口监听"
    echo "   netstat -tlnp | grep 8080"
    echo ""
    echo "   # 测试本地访问"
    echo "   curl http://localhost:8080"
}

# 主函数
main() {
    print_header "网络连接诊断工具"
    print_info "目标地址: http://116.205.173.60:8080/"
    echo ""

    check_network_connectivity
    check_port_binding
    check_firewall
    check_application_status
    check_external_access
    provide_solutions

    print_header "诊断完成"
    print_info "如果问题仍然存在，请检查应用日志或联系技术支持"
}

# 运行主函数
main "$@"
