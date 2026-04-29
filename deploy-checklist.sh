#!/bin/bash

# ========================================
# Linux部署环境检查清单脚本
# ========================================
# 针对部署路径: /ray_tool/custom-function-processor
# 针对应用文件: custom-function-processor-0.0.1-SNAPSHOT.jar
# 用法: ./deploy-checklist.sh

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 输出函数
print_header() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=======================================${NC}"
}

print_check() {
    echo -e "${BLUE}[检查]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

# 检查结果计数
checks_passed=0
checks_failed=0
total_checks=0

# 检查函数
check_item() {
    local description="$1"
    local command="$2"
    local expected_exit=${3:-0}

    ((total_checks++))
    print_check "$description"

    if eval "$command" &>/dev/null; then
        if [ $? -eq $expected_exit ]; then
            print_success "$description"
            ((checks_passed++))
        else
            print_error "$description (退出码不匹配)"
            ((checks_failed++))
        fi
    else
        print_error "$description"
        ((checks_failed++))
    fi
}

# 信息收集函数
collect_info() {
    local description="$1"
    local command="$2"

    print_info "$description"
    eval "$command"
    echo ""
}

# 主检查流程
main() {
    echo ""
    print_header "Linux部署环境检查清单"
    print_info "针对路径: /ray_tool/custom-function-processor"
    print_info "针对文件: custom-function-processor-0.0.1-SNAPSHOT.jar"
    echo ""

    # 1. 系统信息
    print_header "1. 系统环境检查"

    collect_info "操作系统信息" "uname -a"
    collect_info "系统资源" "echo '内存: $(free -h | grep Mem | awk '{print $2}') | 磁盘: $(df -h /ray_tool 2>/dev/null | tail -1 | awk '{print $4}') 可用'"

    # 2. Java环境检查
    print_header "2. Java环境检查"

    check_item "Java已安装" "java -version"
    check_item "Javac编译器可用" "javac -version"

    if command -v java &>/dev/null; then
        collect_info "Java版本详情" "java -version 2>&1 | head -3"
    fi

    # 3. 部署目录检查
    print_header "3. 部署目录检查"

    local app_home="/ray_tool/custom-function-processor"
    collect_info "部署目录" "echo '$app_home'"

    check_item "部署目录存在" "[ -d '$app_home' ]"
    check_item "部署目录可写" "[ -w '$app_home' ]"

    if [ -d "$app_home" ]; then
        collect_info "目录权限详情" "ls -ld '$app_home'"
    fi

    # 4. 应用文件检查
    print_header "4. 应用文件检查"

    local jar_file="$app_home/custom-function-processor-0.0.1-SNAPSHOT.jar"
    local deploy_script="$app_home/linux-deploy.sh"

    check_item "JAR文件存在" "[ -f '$jar_file' ]"
    check_item "部署脚本存在" "[ -f '$deploy_script' ]"

    if [ -f "$jar_file" ]; then
        collect_info "JAR文件详情" "ls -lh '$jar_file'"
    fi

    if [ -f "$deploy_script" ]; then
        collect_info "脚本文件详情" "ls -lh '$deploy_script'"
        check_item "部署脚本可执行" "[ -x '$deploy_script' ]"
    fi

    # 5. 网络和端口检查
    print_header "5. 网络连接检查"

    check_item "网络连接正常" "ping -c 1 8.8.8.8"

    collect_info "端口占用检查" "netstat -tlnp 2>/dev/null | grep :8080 || echo '端口8080未被占用'"

    # 6. 权限检查
    print_header "6. 系统权限检查"

    collect_info "当前用户" "whoami"
    collect_info "用户组" "groups"

    check_item "用户可执行Java" "java -cp . 'public static void main' 2>/dev/null || java -version >/dev/null"

    if [ -f "$jar_file" ]; then
        check_item "用户可读取JAR文件" "[ -r '$jar_file' ]"
    fi

    # 7. 目录结构检查
    print_header "7. 目录结构检查"

    if [ -d "$app_home" ]; then
        print_info "目录结构:"
        ls -la "$app_home" | head -10
        echo ""

        # 检查日志目录
        if [ -d "$app_home/logs" ]; then
            print_info "日志目录内容:"
            ls -la "$app_home/logs" 2>/dev/null | head-5
        else
            print_info "日志目录: 不存在（将在启动时自动创建）"
        fi
        echo ""
    fi

    # 8. 总结报告
    print_header "8. 检查结果总结"

    echo "总检查项: $total_checks"
    echo "通过检查: $checks_passed"
    echo "失败检查: $checks_failed"
    echo ""

    if [ $checks_failed -eq 0 ]; then
        print_success "所有检查均通过！部署环境正常。"
        echo ""
        print_info "接下来可以运行以下命令启动应用:"
        echo "   cd $app_home"
        echo "   ./linux-deploy.sh start"
        echo ""
        print_info "其他可用命令:"
        echo "   ./linux-deploy.sh status   # 查看状态"
        echo "   ./linux-deploy.sh logs     # 查看日志"
        echo "   ./linux-deploy.sh stop     # 停止应用"
        echo "   ./linux-deploy.sh restart  # 重启应用"
    else
        print_warning "发现 $checks_failed 个问题需要解决。"
        echo ""
        print_info "常见解决方案:"
        if ! command -v java &>/dev/null; then
            echo "   - 安装Java: sudo apt-get install openjdk-8-jdk 或 sudo yum install java-1.8.0-openjdk-devel"
        fi
        if [ ! -d "$app_home" ]; then
            echo "   - 创建目录: sudo mkdir -p $app_home && sudo chown \$USER:\$USER $app_home"
        fi
        if [ ! -f "$jar_file" ]; then
            echo "   - 上传JAR文件到: $jar_file"
        fi
        if [ ! -f "$deploy_script" ]; then
            echo "   - 上传部署脚本到: $deploy_script"
            echo "   - 设置执行权限: chmod +x $deploy_script"
        fi
        if ! ping -c 1 8.8.8.8 &>/dev/null; then
            echo "   - 检查网络连接"
        fi
    fi

    echo ""
    print_header "检查完成"
}

# 运行主函数
main "$@"


