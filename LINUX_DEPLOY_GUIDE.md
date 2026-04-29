# Linux服务器部署指南

## 📋 目录
1. [环境要求](#环境要求)
2. [部署前准备](#部署前准备)
3. [文件上传](#文件上传)
4. [服务器配置](#服务器配置)
5. [应用部署](#应用部署)
6. [服务管理](#服务管理)
7. [监控和维护](#监控和维护)
8. [故障排除](#故障排除)

## 🔧 环境要求

### 服务器要求
- **操作系统**: CentOS 7+/Ubuntu 18.04+/Debian 9+
- **内存**: 至少1GB可用内存
- **磁盘**: 至少500MB可用空间
- **网络**: 可访问外网（用于下载依赖）

### Java环境
- **JDK版本**: JDK 8 或更高版本
- **推荐版本**: OpenJDK 8/11/17

### 系统工具
- `wget` 或 `curl`（下载工具）
- `tar`（解压工具）
- `netstat` 或 `ss`（网络工具）
- `ps`、`top`、`htop`（进程监控）

## 🚀 部署前准备

### 1. 服务器环境检查
```bash
# 检查操作系统版本
cat /etc/os-release

# 检查系统架构
uname -m

# 检查可用内存
free -h

# 检查磁盘空间
df -h

# 检查网络连接
ping -c 3 www.baidu.com
```

### 2. 安装Java环境

#### Ubuntu/Debian
```bash
# 更新包索引
sudo apt-get update

# 安装OpenJDK 8
sudo apt-get install openjdk-8-jdk

# 或者安装OpenJDK 11
sudo apt-get install openjdk-11-jdk

# 验证安装
java -version
javac -version
```

#### CentOS/RHEL
```bash
# 安装OpenJDK 8
sudo yum install java-1.8.0-openjdk-devel

# 或者安装OpenJDK 11
sudo yum install java-11-openjdk-devel

# 验证安装
java -version
javac -version
```

### 3. 创建部署目录
```bash
# 创建应用目录
sudo mkdir -p /ray_tool/custom-function-processor

# 设置目录权限（根据实际部署用户调整）
sudo chown -R $USER:$USER /ray_tool/custom-function-processor

# 验证目录创建
ls -la /ray_tool/
```

## 📁 文件上传

### 部署信息
- **服务器路径**: `/ray_tool/custom-function-processor`
- **应用文件**: `custom-function-processor-0.0.1-SNAPSHOT.jar`
- **管理脚本**: `linux-deploy.sh`

### 方法1: 使用SCP上传
```bash
# 从本地上传（Windows PowerShell）
scp target/custom-function-processor-0.0.1-SNAPSHOT.jar user@server:/ray_tool/custom-function-processor/
scp linux-deploy.sh user@server:/ray_tool/custom-function-processor/

# 从本地上传（Linux/Mac）
scp target/custom-function-processor-0.0.1-SNAPSHOT.jar user@server:/ray_tool/custom-function-processor/
scp linux-deploy.sh user@server:/ray_tool/custom-function-processor/
```

### 方法2: 使用SFTP上传
```bash
# 连接到服务器
sftp user@server

# 切换到部署目录
cd /ray_tool/custom-function-processor

# 上传文件
put target/custom-function-processor-0.0.1-SNAPSHOT.jar
put linux-deploy.sh

# 退出SFTP
quit
```

### 方法3: 先下载到服务器
```bash
# 在服务器上下载（如果有外网访问）
cd /ray_tool/custom-function-processor
wget http://your-download-server/custom-function-processor-0.0.1-SNAPSHOT.jar
wget http://your-download-server/linux-deploy.sh
```

## ⚙️ 服务器配置

### 1. 登录到服务器
```bash
# SSH登录
ssh user@server

# 进入部署目录
cd /ray_tool/custom-function-processor
```

### 2. 设置文件权限
```bash
# 给脚本执行权限
chmod +x linux-deploy.sh

# 设置JAR文件权限
chmod 644 custom-function-processor-0.0.1-SNAPSHOT.jar

# 验证文件权限
ls -la
```

### 3. 配置防火墙（如果需要）
```bash
# CentOS/RHEL 7+
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# Ubuntu/Debian
sudo ufw allow 8080
sudo ufw reload
```

## 🚀 应用部署

### 1. 部署环境检查
```bash
# 运行部署检查
./linux-deploy.sh deploy
```

### 2. 启动应用
```bash
# 启动应用
./linux-deploy.sh start
```

### 3. 验证部署
```bash
# 查看应用状态
./linux-deploy.sh status

# 查看启动日志
./linux-deploy.sh logs
```

### 4. 测试应用
```bash
# 访问应用首页
curl http://localhost:8080

# 访问API接口
curl http://localhost:8080/api/functions

# 检查端口监听
netstat -tlnp | grep :8080
```

## 🔧 服务管理

### 基本管理命令
```bash
# 启动应用
./linux-deploy.sh start

# 停止应用
./linux-deploy.sh stop

# 重启应用
./linux-deploy.sh restart

# 查看状态
./linux-deploy.sh status

# 查看日志
./linux-deploy.sh logs
```

### 后台运行和管理
```bash
# 使用screen管理会话
sudo yum install screen  # CentOS/RHEL
sudo apt-get install screen  # Ubuntu/Debian

# 创建screen会话
screen -S custom-function-processor

# 在screen中运行日志查看
./linux-deploy.sh logs

# 脱离screen会话 (Ctrl+A+D)
# 重新连接screen会话
screen -r custom-function-processor
```

### 系统服务配置（可选）
```bash
# 创建systemd服务文件
sudo tee /etc/systemd/system/custom-function-processor.service > /dev/null <<EOF
[Unit]
Description=Custom Function Processor
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/ray_tool/custom-function-processor
ExecStart=/ray_tool/custom-function-processor/linux-deploy.sh start
ExecStop=/ray_tool/custom-function-processor/linux-deploy.sh stop
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start custom-function-processor

# 设置开机自启
sudo systemctl enable custom-function-processor

# 查看服务状态
sudo systemctl status custom-function-processor

# 查看服务日志
sudo journalctl -u custom-function-processor -f
```

## 📊 监控和维护

### 应用监控
```bash
# 查看应用状态
./linux-deploy.sh status

# 监控进程
ps aux | grep java

# 监控端口
netstat -tlnp | grep :8080

# 监控资源使用
top -p $(cat app.pid)
```

### 日志管理
```bash
# 实时查看日志
./linux-deploy.sh logs

# 查看日志文件
tail -f logs/app.log

# 搜索日志中的错误
grep -i error logs/app.log

# 日志轮转（防止日志文件过大）
# 创建日志轮转配置
sudo tee /etc/logrotate.d/custom-function-processor > /dev/null <<EOF
/ray_tool/custom-function-processor/logs/app.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 $USER $USER
    postrotate
        # 重启应用以使用新的日志文件
        /ray_tool/custom-function-processor/linux-deploy.sh restart
    endscript
}
EOF
```

### 性能监控
```bash
# JVM内存使用情况
jstat -gc $(cat app.pid) 1000 5

# JVM堆使用情况
jmap -heap $(cat app.pid)

# 生成堆转储（故障排查）
jmap -dump:live,format=b,file=heap.dump $(cat app.pid)

# JVM线程信息
jstack $(cat app.pid)
```

## 🔍 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 查看端口占用
netstat -tlnp | grep :8080

# 杀死占用进程
sudo kill -9 <PID>

# 或者使用lsof
sudo lsof -ti:8080 | xargs kill -9
```

#### 2. 权限问题
```bash
# 检查文件权限
ls -la /ray_tool/custom-function-processor/

# 修复权限
chmod +x /ray_tool/custom-function-processor/linux-deploy.sh
chmod 644 /ray_tool/custom-function-processor/*.jar

# 检查用户权限
whoami
groups
```

#### 3. 内存不足
```bash
# 检查系统内存
free -h

# 检查JVM内存设置
ps aux | grep java

# 调整JVM参数（在脚本中）
JAVA_OPTS="-Xms256m -Xmx512m ..."
```

#### 4. 启动失败
```bash
# 查看详细日志
./linux-deploy.sh logs

# 检查Java版本
java -version

# 手动测试启动
java -jar custom-function-processor-0.0.1-SNAPSHOT.jar

# 检查依赖项
ldd /usr/lib/jvm/java-*/bin/java
```

#### 5. 网络问题
```bash
# 测试网络连接
ping -c 3 8.8.8.8

# 检查防火墙
# CentOS/RHEL
sudo firewall-cmd --list-all

# Ubuntu/Debian
sudo ufw status

# 检查SELinux
sestatus
```

### 快速诊断脚本
```bash
# 创建诊断脚本
tee diagnose.sh > /dev/null <<EOF
#!/bin/bash
echo "=== 系统信息 ==="
uname -a
echo ""

echo "=== Java版本 ==="
java -version
echo ""

echo "=== 内存信息 ==="
free -h
echo ""

echo "=== 磁盘信息 ==="
df -h /ray_tool
echo ""

echo "=== 应用文件 ==="
ls -la /ray_tool/custom-function-processor/
echo ""

echo "=== 进程信息 ==="
ps aux | grep java | grep -v grep
echo ""

echo "=== 端口信息 ==="
netstat -tlnp | grep :8080
echo ""

echo "=== 最近日志 ==="
tail -20 /ray_tool/custom-function-processor/logs/app.log 2>/dev/null || echo "日志文件不存在"
EOF

chmod +x diagnose.sh
./diagnose.sh
```

## 📞 技术支持

### 获取帮助
1. **查看脚本帮助**: `./linux-deploy.sh help`
2. **检查状态**: `./linux-deploy.sh status`
3. **查看日志**: `./linux-deploy.sh logs`
4. **运行诊断**: `./diagnose.sh`

### 紧急处理
```bash
# 强制停止应用
pkill -f custom-function-processor

# 清理PID文件
rm -f app.pid

# 重启应用
./linux-deploy.sh start

# 恢复最近的备份
# cp backup/app.jar.custom-function-processor-0.0.1-SNAPSHOT.jar .
```

---

## 🎯 总结

按照本指南完成部署后，您将拥有一个稳定运行在Linux服务器上的Spring Boot应用，并配备了完整的管理工具和监控能力。

**部署信息:**
- 应用目录: `/ray_tool/custom-function-processor`
- 应用文件: `custom-function-processor-0.0.1-SNAPSHOT.jar`
- 管理脚本: `linux-deploy.sh`
- 日志文件: `logs/app.log`
- PID文件: `app.pid`

**常用命令:**
- 启动: `./linux-deploy.sh start`
- 停止: `./linux-deploy.sh stop`
- 状态: `./linux-deploy.sh status`
- 日志: `./linux-deploy.sh logs`

祝部署顺利！🚀

