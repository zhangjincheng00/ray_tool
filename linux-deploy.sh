#!/bin/bash

# ========================================
# 自定义功能配置器 - Linux服务器部署脚本
# ========================================
# 部署路径: /ray_tool/custom-function-processor
# JAR文件: custom-function-processor-0.0.1-SNAPSHOT.jar
# 用法: ./linux-deploy.sh {start|stop|restart|status|logs|deploy}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 输出带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 应用配置 - 针对指定部署环境
APP_NAME="custom-function-processor"
APP_HOME="/ray_tool/custom-function-processor"
JAR_FILE="$APP_HOME/custom-function-processor-0.0.1-SNAPSHOT.jar"
LOG_FILE="$APP_HOME/logs/app.log"
PID_FILE="$APP_HOME/app.pid"
LOG_DIR="$APP_HOME/logs"

# JVM参数（生产环境优化）
JAVA_OPTS="-Xms256m -Xmx256m -XX:+UseG1GC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Djava.security.egd=file:/dev/./urandom"

# 显示帮助信息
show_help() {
    echo "========================================"
    echo "  自定义功能配置器 - Linux部署脚本"
    echo "========================================"
    echo ""
    echo "部署路径: $APP_HOME"
    echo "应用文件: custom-function-processor-0.0.1-SNAPSHOT.jar"
    echo ""
    echo "用法: $0 {start|stop|restart|status|logs|deploy}"
    echo ""
    echo "命令说明:"
    echo "  start   启动应用"
    echo "  stop    停止应用"
    echo "  restart 重启应用"
    echo "  status  查看应用状态"
    echo "  logs    查看应用日志"
    echo "  deploy  部署环境检查"
    echo ""
    echo "示例:"
    echo "  $0 start    # 启动应用"
    echo "  $0 stop     # 停止应用"
    echo "  $0 restart  # 重启应用"
    echo "  $0 status   # 查看状态"
    echo "  $0 logs     # 查看日志"
    echo "  $0 deploy   # 部署检查"
    echo ""
    exit 0
}

# 检查Java环境
check_java() {
    print_info "检查Java环境..."

    if ! command -v java &> /dev/null; then
        print_error "Java 未安装或不在 PATH 中"
        print_info "请安装 JDK 8 或更高版本"
        echo "  Ubuntu/Debian: sudo apt-get install openjdk-8-jdk"
        echo "  CentOS/RHEL: sudo yum install java-1.8.0-openjdk-devel"
        exit 1
    fi

    local java_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
    print_success "Java版本: $java_version"
}

# 检查并创建必要目录
check_directories() {
    print_info "检查应用目录..."

    # 检查应用目录是否存在
    if [ ! -d "$APP_HOME" ]; then
        print_error "应用目录不存在: $APP_HOME"
        print_info "请确保已创建应用目录"
        echo "  sudo mkdir -p $APP_HOME"
        echo "  sudo chown 当前用户:当前用户 $APP_HOME"
        exit 1
    fi

    # 创建日志目录
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        print_success "创建日志目录: $LOG_DIR"
    fi

    # 检查应用目录权限
    if [ ! -w "$APP_HOME" ]; then
        print_error "应用目录没有写入权限: $APP_HOME"
        print_info "请检查目录权限"
        echo "  ls -la $APP_HOME"
        exit 1
    fi

    print_success "应用目录检查完成"
}

# 检查应用文件
check_app() {
    print_info "检查应用文件..."
    echo "   查找路径: $APP_HOME"
    echo "   目标文件: $JAR_FILE"

    if [ ! -f "$JAR_FILE" ]; then
        echo ""
        print_error "JAR 文件不存在!"
        echo "   期望位置: $JAR_FILE"
        echo ""
        print_info "🔧 解决方案:"
        echo "   1. 请确保已将JAR文件上传到正确位置"
        echo "   2. 检查文件路径是否正确"
        echo "   3. 运行以下命令检查当前目录文件:"
        echo ""
        echo "   ls -la $APP_HOME"
        echo ""
        print_info "📂 当前目录文件列表:"
        ls -la "$APP_HOME" 2>/dev/null | head -10
        echo ""
        if [ -d "$APP_HOME/logs" ]; then
            print_info "📂 logs目录文件列表:"
            ls -la "$APP_HOME/logs" 2>/dev/null | head-5
        fi
        echo ""
        exit 1
    fi

    local jar_size=$(du -h "$JAR_FILE" | cut -f1)
    print_success "找到JAR文件: $JAR_FILE (${jar_size})"
}

# 获取进程ID
get_pid() {
    if [ -f "$PID_FILE" ]; then
        cat "$PID_FILE" 2>/dev/null
    fi
}

# 检查应用是否在运行
is_running() {
    local pid=$(get_pid)
    if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
        return 0  # 正在运行
    else
        # 清理过期的PID文件
        if [ -f "$PID_FILE" ]; then
            rm -f "$PID_FILE"
        fi
        return 1  # 未运行
    fi
}

# 启动应用
start_app() {
    print_info "正在启动 $APP_NAME..."

    # 检查是否已在运行
    if is_running; then
        local pid=$(get_pid)
        print_warning "$APP_NAME 已在运行 (PID: $pid)"
        exit 1
    fi

    # 环境检查
    check_java
    check_directories
    check_app

    print_info "启动参数:"
    echo "   JAR文件: $JAR_FILE"
    echo "   日志文件: $LOG_FILE"
    echo "   JVM参数: $JAVA_OPTS"
    echo ""

    # 创建日志目录
    mkdir -p "$LOG_DIR"

    # 启动应用
    cd "$APP_HOME"

    # 后台启动应用
    nohup java $JAVA_OPTS -jar "$JAR_FILE" > "$LOG_FILE" 2>&1 &
    local pid=$!

    # 等待一秒检查进程
    sleep 2

    if ps -p "$pid" > /dev/null 2>&1; then
        echo "$pid" > "$PID_FILE"
        print_success "$APP_NAME 启动成功! (PID: $pid)"

        # 等待应用完全启动
        print_info "等待应用完全启动..."
        local count=0
        local max_wait=30
        while [ $count -lt $max_wait ]; do
            if grep -q "Started CustomFunctionProcessorApplication" "$LOG_FILE" 2>/dev/null; then
                print_success "应用已完全启动!"
                echo ""
                echo "========================================"
                print_success "🌐 访问地址: http://localhost:8080"
                print_info "📊 API接口: http://localhost:8080/api/functions"
                print_info "📝 查看日志: $0 logs"
                print_info "🛑 停止应用: $0 stop"
                echo "========================================"
                return 0
            fi
            sleep 1
            count=$((count + 1))
        done
        print_warning "应用可能仍在启动中，请稍后检查状态"
    else
        print_error "启动失败，请检查日志文件"
        print_info "查看日志: $0 logs"
        exit 1
    fi
}

# 停止应用
stop_app() {
    print_info "正在停止 $APP_NAME..."

    if ! is_running; then
        print_info "$APP_NAME 未在运行"
        return 0
    fi

    local pid=$(get_pid)
    print_info "正在停止进程 (PID: $pid)..."

    # 优雅停止
    kill "$pid" 2>/dev/null

    # 等待进程停止
    local timeout=30
    local count=0
    while [ $count -lt $timeout ] && is_running; do
        sleep 1
        count=$((count + 1))
        echo -n "."
    done
    echo ""

    # 如果仍在运行，强制终止
    if is_running; then
        print_warning "进程未响应，正在强制终止..."
        kill -9 "$pid" 2>/dev/null
        sleep 2
    fi

    if ! is_running; then
        rm -f "$PID_FILE"
        print_success "$APP_NAME 已停止"
    else
        print_error "无法停止应用"
        exit 1
    fi
}

# 重启应用
restart_app() {
    print_info "正在重启 $APP_NAME..."
    stop_app
    sleep 2
    start_app
}

# 查看状态
show_status() {
    echo "========================================"
    print_info "$APP_NAME 状态信息:"
    echo "========================================"

    if is_running; then
        local pid=$(get_pid)
        local uptime=$(ps -p "$pid" -o etime= | tr -d ' ')
        local memory=$(ps -p "$pid" -o rss= | tr -d ' ')
        local memory_mb=$((memory / 1024))

        print_success "状态: 运行中"
        echo "🔢 进程ID: $pid"
        echo "⏱️  运行时间: $uptime"
        echo "💾 内存使用: ${memory_mb}MB"

        # 检查端口
        if command -v netstat &> /dev/null; then
            if netstat -tlnp 2>/dev/null | grep :8080 | grep -q "$pid"; then
                print_success "端口状态: 8080 (正常)"
            else
                print_warning "端口状态: 8080 (未监听)"
            fi
        fi
    else
        print_error "状态: 未运行"
    fi

    echo "📁 应用目录: $APP_HOME"
    echo "📄 应用文件: $([ -f "$JAR_FILE" ] && echo "存在" || echo "不存在")"
    echo "📝 日志文件: $([ -f "$LOG_FILE" ] && echo "存在" || echo "不存在")"
    echo "📂 当前工作目录: $(pwd)"
}

# 查看日志
show_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        print_error "日志文件不存在: $LOG_FILE"
        print_info "请先启动应用"
        exit 1
    fi

    print_info "正在显示 $APP_NAME 日志 (按 Ctrl+C 退出):"
    echo "========================================"
    tail -f "$LOG_FILE"
}

# 部署检查
deploy_check() {
    print_info "开始部署环境检查..."
    echo ""

    # 检查操作系统
    print_info "操作系统信息:"
    uname -a
    echo ""

    # 检查Java
    check_java
    echo ""

    # 检查目录权限
    check_directories
    echo ""

    # 检查应用文件
    check_app
    echo ""

    # 检查网络
    print_info "网络连接检查:"
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "网络连接正常"
    else
        print_warning "网络连接异常"
    fi
    echo ""

    # 检查端口占用
    print_info "端口占用检查:"
    if command -v netstat &> /dev/null; then
        if netstat -tlnp 2>/dev/null | grep :8080 | grep -v grep; then
            print_warning "端口8080已被占用"
        else
            print_success "端口8080可用"
        fi
    else
        print_info "netstat命令不可用，跳过端口检查"
    fi
    echo ""

    print_success "部署环境检查完成!"
    echo ""
    print_info "如果检查通过，可以运行以下命令启动应用:"
    echo "   $0 start"
}

# 主函数
main() {
    local command="$1"

    case "$command" in
        start)
            start_app
            ;;
        stop)
            stop_app
            ;;
        restart)
            restart_app
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        deploy)
            deploy_check
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "无效命令: $command"
            echo ""
            show_help
            ;;
    esac
}

# 执行主函数
if [ $# -eq 0 ]; then
    show_help
else
    main "$1"
fi
