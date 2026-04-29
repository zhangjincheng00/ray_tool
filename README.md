# Custom Function Processor

一个基于Spring Boot的通用Web应用程序，支持根据后端方法进行自定义功能配置。用户可以通过现代化的Web界面选择不同的处理功能，输入数据，获得相应的处理结果。

## 功能特性

- 🎨 **现代化UI**: 基于Material Design 3.0风格的响应式界面
- 🔧 **动态功能注册**: 通过注解自动发现和注册处理方法
- 📱 **多功能支持**: 内置JSON/XML转换、文本处理、开发工具等功能
- 🎯 **高度可扩展**: 支持动态添加新的处理功能
- 🌙 **主题系统**: 支持明暗主题切换
- 🔍 **智能搜索**: 功能搜索和分类过滤
- 📋 **批量处理**: 支持多文件批量处理
- 💾 **数据持久化**: 本地存储配置和历史记录

## 技术栈

- **后端**: Spring Boot 2.7.0, Java 8
- **前端**: HTML5, CSS3, JavaScript (原生)
- **模板引擎**: Thymeleaf
- **数据处理**: Jackson, Apache Commons
- **构建工具**: Maven

## 快速开始

### 环境要求

- JDK 8+
- Maven 3.6+

### 本地运行

1. **编译项目**
   ```bash
   mvn clean compile
   ```

2. **打包应用**
   ```bash
   mvn package -DskipTests
   ```

3. **启动应用**
   ```bash
   ./manage.sh start
   ```

4. **访问应用**
   打开浏览器访问: http://localhost:8080

### 停止应用
```bash
./manage.sh stop
```

## 📋 脚本使用

### `manage.sh` - 应用管理脚本
项目根目录下的 `manage.sh` 脚本提供了以下功能：

```bash
# 启动应用
./manage.sh start

# 停止应用
./manage.sh stop

# 重启应用
./manage.sh restart

# 查看应用状态
./manage.sh status

# 查看应用日志
./manage.sh logs

# 显示帮助信息
./manage.sh help
```

### Linux服务器部署

#### 部署信息
- **服务器路径**: `/ray_tool/custom-function-processor`
- **应用文件**: `custom-function-processor-0.0.1-SNAPSHOT.jar`
- **管理脚本**: `linux-deploy.sh`

#### 1. 上传文件到服务器
```bash
# 上传JAR包到指定路径
scp target/custom-function-processor-0.0.1-SNAPSHOT.jar user@server:/ray_tool/custom-function-processor/

# 上传Linux部署脚本
scp linux-deploy.sh user@server:/ray_tool/custom-function-processor/

# 上传部署检查脚本（可选）
scp deploy-checklist.sh user@server:/ray_tool/custom-function-processor/
```

#### 2. 服务器部署检查
```bash
# 登录到服务器
ssh user@server

# 进入部署目录
cd /ray_tool/custom-function-processor

# 设置脚本执行权限
chmod +x linux-deploy.sh
chmod +x deploy-checklist.sh

# 运行部署环境检查
./deploy-checklist.sh
```

#### 3. 启动应用
```bash
# 启动应用
./linux-deploy.sh start

# 查看状态
./linux-deploy.sh status

# 查看日志
./linux-deploy.sh logs
```

#### 4. 停止应用
```bash
# 停止应用
./linux-deploy.sh stop

# 重启应用
./linux-deploy.sh restart
```

#### 5. 网络诊断和修复
如果遇到无法访问的问题，可以使用以下脚本：

```bash
# 运行网络诊断脚本
./network-diagnostic.sh

# 运行快速修复脚本
./quick-fix.sh
```

## 项目结构

```
custom-function-processor/
├── src/main/java/com/processor/
│   ├── CustomFunctionProcessorApplication.java    # 主启动类
│   ├── controller/
│   │   └── ProcessorController.java               # Web控制器
│   ├── service/
│   │   ├── FunctionRegistry.java                  # 功能注册服务
│   │   └── ProcessorService.java                  # 处理服务
│   ├── config/
│   │   └── ProcessorConfig.java                   # 配置管理
│   ├── model/
│   │   ├── FunctionDefinition.java                # 功能定义
│   │   └── ProcessResult.java                     # 处理结果
│   ├── annotation/
│   │   ├── FunctionProcessor.java                 # 功能处理器注解
│   │   ├── ProcessMethod.java                     # 处理方法注解
│   │   ├── InputParam.java                        # 输入参数注解
│   │   └── OptionParam.java                       # 选项参数注解
│   └── processor/
│       ├── JsonXmlConverter.java                  # JSON/XML转换器
│       ├── NumberProcessor.java                   # 数字字符转换器
│       └── PathProcessor.java                     # 路径转换器
├── src/main/resources/
│   ├── static/
│   │   ├── css/modern-style.css                  # 现代化样式
│   │   ├── js/processor-app.js                   # 前端应用逻辑
│   │   └── icons/function-icons.svg              # 功能图标
│   ├── templates/index.html                      # 主页面模板
│   └── application.yml                           # 应用配置
├── pom.xml                                       # Maven配置
├── manage.sh                                     # 本地应用管理脚本
├── linux-deploy.sh                               # Linux部署管理脚本
├── deploy-checklist.sh                           # 部署环境检查脚本
├── network-diagnostic.sh                         # 网络诊断脚本
├── quick-fix.sh                                  # 快速修复脚本
├── LINUX_DEPLOY_GUIDE.md                        # Linux部署详细指南
└── README.md                                     # 项目说明
```

### 📚 详细文档

- **`LINUX_DEPLOY_GUIDE.md`** - Linux服务器部署详细指南
- **`TROUBLESHOOTING.md`** - 故障排除指南（解决无法访问的问题）
- **`deploy-checklist.sh`** - 部署环境检查脚本
- **`network-diagnostic.sh`** - 网络诊断脚本
- **`quick-fix.sh`** - 快速修复脚本（一键解决访问问题）

## 内置功能

### 1. 格式转换 (多功能转换器)
- **JSON XML转换**: JSON和XML格式互相转换
- **自动格式检测**: 自动检测输入格式并转换为另一种格式
- **格式化输出**: 美化JSON/XML格式

### 2. 路径转换 (路径转换器)
- **路径转换**: 将Java项目路径转换为JAR命令格式
- **文件扩展名转换**: 自动将.java文件扩展名转换为.class
- **多项目支持**: 支持iom-north-interface、iom-south-interface、iom-cloud-province-special等项目的路径转换

### 3. 数字转换 (数字字符转换器)
- **数字转字符串**: 将多行数字转换为字符串格式
- **数字转字符串数组**: 将多行数字转换为JSON数组格式
- **数字转数字串(逗号分隔)**: 将多行数字用逗号连接

## API接口

### 获取功能列表
```http
GET /api/functions
GET /api/functions?category=format
GET /api/functions?search=json
```

### 执行功能处理
```http
POST /api/process
Content-Type: application/json

{
  "function": "json-xml-converter",
  "input": "{\"name\": \"test\"}",
  "options": {
    "pretty": true
  }
}
```

### 响应格式
```json
{
  "success": true,
  "result": "<xml>...</xml>",
  "processingTime": 15,
  "resultFormat": "xml"
}
```

## 扩展开发

### 创建新的功能处理器

1. **创建处理器类**
```java
@Component
@FunctionProcessor(
    name = "my-custom-function",
    displayName = "我的自定义功能",
    description = "自定义功能描述",
    category = "custom",
    icon = "settings"
)
public class MyCustomProcessor {

    @ProcessMethod("process")
    public ProcessResult process(
            @InputParam(displayName = "输入内容", description = "要处理的内容")
            String input,
            @OptionParam(value = "option1", displayName = "选项1", defaultValue = "default")
            String option1
    ) {
        // 处理逻辑
        String result = processInput(input, option1);
        return ProcessResult.success(result);
    }
}
```

2. **功能自动注册**
   重启应用后，新功能会自动出现在界面中，无需额外配置。

### 自定义主题

修改 `src/main/resources/application.yml` 中的UI配置：

```yaml
processor:
  ui:
    primary-color: "#your-color"
    secondary-color: "#your-color"
    theme: "light" # 或 "dark"
```

## 配置说明

### 应用配置 (application.yml)

```yaml
server:
  port: 8080

processor:
  functions:
    # 功能配置
    text-processing:
      enabled: true
  ui:
    # UI配置
    theme: "light"
    primary-color: "#6366f1"
  cache:
    # 缓存配置
    enabled: true
  security:
    # 安全配置
    cors-enabled: true
```

## 部署说明

### 开发环境
```bash
mvn spring-boot:run
```

### 生产环境
```bash
mvn clean package
java -jar target/custom-function-processor-0.0.1-SNAPSHOT.jar
```

### Docker部署
```bash
docker build -t custom-function-processor .
docker run -p 8080:8080 custom-function-processor
```

## 性能优化

- **缓存**: 内置Caffeine缓存支持
- **异步处理**: 支持异步功能处理
- **响应式设计**: 移动端优化
- **懒加载**: 按需加载功能模块

## 安全特性

- CORS支持
- 请求频率限制
- 输入验证
- XSS防护

## 浏览器支持

- Chrome 70+
- Firefox 65+
- Safari 12+
- Edge 79+

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

项目维护者: [Your Name]
邮箱: your.email@example.com

项目主页: [项目地址]

---

⭐ 如果这个项目对你有帮助，请给它一个 star！
