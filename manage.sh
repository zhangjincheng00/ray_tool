#!/bin/bash

# ========================================
# 自定义功能配置器 - 应用管理脚本
# ========================================
# 用法: ./manage.sh {start|stop|restart|status|logs}

# 应用配置
APP_NAME="custom-function-processor"
APP_HOME="$(cd "$(dirname "$0")"; pwd)"
JAR_FILE="$APP_HOME/target/custom-function-processor-0.0.1-SNAPSHOT.jar"
LOG_FILE="$APP_HOME/logs/app.log"
PID_FILE="$APP_HOME/app.pid"
LOG_DIR="$APP_HOME/logs"

# JVM参数
JAVA_OPTS="-Xms256m -Xmx256m -XX:+UseG1GC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps"

# 显示帮助信息
show_help() {
    echo "========================================"
    echo "  自定义功能配置器 - 管理脚本"
    echo "========================================"
    echo ""
    echo "用法: $0 {start|stop|restart|status|logs}"
    echo ""
    echo "命令说明:"
    echo "  start   启动应用"
    echo "  stop    停止应用"
    echo "  restart 重启应用"
    echo "  status  查看应用状态"
    echo "  logs    查看应用日志"
    echo ""
    echo "示例:"
    echo "  $0 start    # 启动应用"
    echo "  $0 stop     # 停止应用"
    echo "  $0 restart  # 重启应用"
    echo "  $0 status   # 查看状态"
    echo "  $0 logs     # 查看日志"
    echo ""
    exit 0
}

# 检查Java环境
check_java() {
    if ! command -v java &> /dev/null; then
        echo "❌ 错误: Java 未安装或不在 PATH 中"
        echo "请安装 JDK 8 或更高版本"
        exit 1
    fi
}

# 检查应用文件
check_app() {
    if [ ! -f "$JAR_FILE" ]; then
        echo "❌ 错误: JAR 文件不存在: $JAR_FILE"
        echo "请先运行 'mvn clean package' 构建项目"
        exit 1
    fi
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
    echo "🚀 正在启动 $APP_NAME..."

    # 检查是否已在运行
    if is_running; then
        echo "⚠️  警告: $APP_NAME 已在运行 (PID: $(get_pid))"
        exit 1
    fi

    # 检查环境
    check_java
    check_app

    # 创建日志目录
    mkdir -p "$LOG_DIR"

    # 启动应用
    echo "📝 日志文件: $LOG_FILE"
    cd "$APP_HOME"

    # 启动应用
    java $JAVA_OPTS -jar "$JAR_FILE" > "$LOG_FILE" 2>&1 &
    local pid=$!

    # 等待一秒检查进程
    sleep 2

    if ps -p "$pid" > /dev/null 2>&1; then
        echo "$pid" > "$PID_FILE"
        echo "✅ $APP_NAME 启动成功! (PID: $pid)"

        # 等待应用完全启动
        echo "⏳ 等待应用完全启动..."
        local count=0
        local max_wait=30
        while [ $count -lt $max_wait ]; do
            if grep -q "Started CustomFunctionProcessorApplication" "$LOG_FILE" 2>/dev/null; then
                echo "🎉 应用已完全启动!"
                echo ""
                echo "========================================"
                echo "🌐 访问地址: http://localhost:8080"
                echo "📊 API接口: http://localhost:8080/api/functions"
                echo "📝 查看日志: $0 logs"
                echo "🛑 停止应用: $0 stop"
                echo "========================================"
                return 0
            fi
            sleep 1
            count=$((count + 1))
        done
        echo "⚠️  应用可能仍在启动中，请稍后检查状态"
    else
        echo "❌ 启动失败，请检查日志文件"
        echo "📝 查看日志: $0 logs"
        exit 1
    fi
}

# 停止应用
stop_app() {
    echo "🛑 正在停止 $APP_NAME..."

    if ! is_running; then
        echo "ℹ️  $APP_NAME 未在运行"
        return 0
    fi

    local pid=$(get_pid)
    echo "🔄 正在停止进程 (PID: $pid)..."

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
        echo "⚠️  进程未响应，正在强制终止..."
        kill -9 "$pid" 2>/dev/null
        sleep 2
    fi

    if ! is_running; then
        rm -f "$PID_FILE"
        echo "✅ $APP_NAME 已停止"
    else
        echo "❌ 无法停止应用"
        exit 1
    fi
}

# 重启应用
restart_app() {
    echo "🔄 正在重启 $APP_NAME..."
    stop_app
    sleep 2
    start_app
}

# 查看状态
show_status() {
    echo "📊 $APP_NAME 状态信息:"
    echo "========================================"

    if is_running; then
        local pid=$(get_pid)
        local uptime=$(ps -p "$pid" -o etime= | tr -d ' ')
        local memory=$(ps -p "$pid" -o rss= | tr -d ' ')
        local memory_mb=$((memory / 1024))

        echo "✅ 状态: 运行中"
        echo "🔢 进程ID: $pid"
        echo "⏱️  运行时间: $uptime"
        echo "💾 内存使用: ${memory_mb}MB"

        # 检查端口
        if command -v netstat &> /dev/null; then
            if netstat -tlnp 2>/dev/null | grep :8080 | grep -q "$pid"; then
                echo "🌐 端口状态: 8080 (正常)"
            else
                echo "⚠️  端口状态: 8080 (未监听)"
            fi
        fi
    else
        echo "❌ 状态: 未运行"
    fi

    echo "📁 应用目录: $APP_HOME"
    echo "📄 应用文件: $([ -f "$JAR_FILE" ] && echo "存在" || echo "不存在")"
    echo "📝 日志文件: $([ -f "$LOG_FILE" ] && echo "存在" || echo "不存在")"
}

# 查看日志
show_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "❌ 日志文件不存在: $LOG_FILE"
        echo "请先启动应用"
        exit 1
    fi

    echo "📋 正在显示 $APP_NAME 日志 (按 Ctrl+C 退出):"
    echo "=========================================="
    tail -f "$LOG_FILE"
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
        help|--help|-h)
            show_help
            ;;
        *)
            echo "❌ 无效命令: $command"
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
