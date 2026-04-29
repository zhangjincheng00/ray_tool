# 故障排除指南

## 无法访问 http://116.205.173.60:8080/ 的问题

### 🚨 问题现象
- 浏览器显示"无法访问此页面"或"花了太长时间进行响应"
- 应用在服务器上显示启动成功
- 本地curl测试失败

### 🔍 快速诊断

#### 1. 使用网络诊断脚本
```bash
# 在服务器上运行
cd /ray_tool/custom-function-processor
./network-diagnostic.sh
```

#### 2. 手动检查步骤
```bash
# 检查应用进程
ps aux | grep java

# 检查端口监听
netstat -tlnp | grep 8080

# 检查防火墙
sudo firewall-cmd --list-all  # CentOS/RHEL
sudo ufw status               # Ubuntu/Debian

# 测试本地访问
curl http://localhost:8080

# 查看应用日志
tail -f logs/app.log
```

### 🛠️ 解决方案

#### 方案1：使用快速修复脚本（推荐）
```bash
cd /ray_tool/custom-function-processor
./quick-fix.sh
```

#### 方案2：手动修复步骤

##### 2.1 检查端口绑定
应用可能绑定到localhost而不是所有网络接口。

**检查当前绑定：**
```bash
netstat -tlnp | grep 8080
```

**修复端口绑定：**
1. 确保JVM参数包含：`-Dserver.address=0.0.0.0`
2. 重新启动应用：
```bash
./linux-deploy.sh stop
./linux-deploy.sh start
```

##### 2.2 检查防火墙设置
服务器防火墙可能阻止了8080端口的访问。

**CentOS/RHEL系统：**
```bash
# 检查firewalld状态
sudo firewall-cmd --state

# 添加端口规则
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# 验证规则
sudo firewall-cmd --list-all
```

**Ubuntu/Debian系统：**
```bash
# 检查ufw状态
sudo ufw status

# 允许端口访问
sudo ufw allow 8080

# 验证规则
sudo ufw status
```

##### 2.3 检查应用状态
确保应用正确启动并运行。

```bash
# 检查应用状态
./linux-deploy.sh status

# 查看应用日志
./linux-deploy.sh logs

# 重启应用
./linux-deploy.sh restart
```

##### 2.4 验证网络配置
检查服务器网络配置是否正确。

```bash
# 检查网络接口
ip addr show

# 检查路由表
ip route show

# 测试网络连通性
ping -c 3 8.8.8.8

# 检查DNS解析
nslookup 116.205.173.60
```

### 🔧 高级故障排除

#### 3.1 检查系统资源
应用可能因资源不足而无法正常响应。

```bash
# 检查内存使用
free -h

# 检查磁盘空间
df -h

# 检查CPU负载
top
```

#### 3.2 检查Java进程
验证Java应用进程状态。

```bash
# 查找Java进程
ps aux | grep java | grep -v grep

# 检查进程详细信息
ps -p <PID> -o pid,ppid,cmd,pcpu,pmem

# 检查JVM内存使用
jstat -gc <PID>
```

#### 3.3 检查应用配置
验证Spring Boot应用配置。

```bash
# 检查application.yml配置
cat src/main/resources/application.yml

# 检查JVM参数
ps aux | grep java | grep -o "D[^ ]*" | tr '\n' ' '
```

#### 3.4 检查安全设置
服务器安全设置可能阻止访问。

```bash
# 检查SELinux状态
sestatus

# 检查AppArmor状态（Ubuntu）
sudo apparmor_status

# 检查安全组设置（云服务器）
# 根据云服务商文档检查安全组规则
```

### 📋 常用修复命令

#### 防火墙修复
```bash
# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8080/tcp && sudo firewall-cmd --reload

# Ubuntu/Debian
sudo ufw allow 8080 && sudo ufw reload
```

#### 应用重启
```bash
cd /ray_tool/custom-function-processor
./linux-deploy.sh stop
sleep 3
./linux-deploy.sh start
```

#### 网络测试
```bash
# 测试本地访问
curl -v http://localhost:8080

# 测试外部访问
curl -v http://116.205.173.60:8080

# 测试端口连通性
telnet 116.205.173.60 8080
```

### 🚀 预防措施

#### 1. 部署前检查
```bash
# 使用部署检查脚本
./deploy-checklist.sh
```

#### 2. 启动后验证
```bash
# 检查端口监听
netstat -tlnp | grep 8080

# 测试访问
curl http://localhost:8080
curl http://116.205.173.60:8080
```

#### 3. 监控设置
```bash
# 设置定期检查
crontab -e
# 添加：*/5 * * * * /ray_tool/custom-function-processor/linux-deploy.sh status
```

### 📞 获取帮助

如果以上方法都无法解决问题：

1. **收集诊断信息**
   ```bash
   ./network-diagnostic.sh > diagnostic.log
   ```

2. **检查系统日志**
   ```bash
   dmesg | tail -20
   journalctl -n 20
   ```

3. **联系技术支持**
   - 提供diagnostic.log文件
   - 说明具体的错误现象
   - 提供系统环境信息

---

## 🎯 总结

**最常见的原因：**
1. **防火墙阻止** - 端口8080被防火墙阻止
2. **端口绑定** - 应用绑定到localhost而不是0.0.0.0
3. **应用未启动** - 应用进程异常退出

**最快的解决方法：**
```bash
cd /ray_tool/custom-function-processor
./quick-fix.sh
```

**验证方法：**
```bash
curl http://116.205.173.60:8080
```

祝您问题顺利解决！🚀
