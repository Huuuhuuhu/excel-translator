# zyt's translator

基于 Streamlit 的翻译工具，支持 Excel 翻译和图片表格识别翻译。

## 功能

- Excel 翻译：上传 `.xlsx` 文件，自动翻译所有文本内容
- 图片翻译：上传表格图片，识别表格结构并翻译，输出为 Excel

## 部署指南（Linux）

### 1. 安装系统软件

```bash
sudo apt update

# 安装 Python 3.8+（如果没有）
sudo apt install python3 python3-venv python3-pip

# 安装 nginx
sudo apt install nginx
```

### 2. 上传项目

将项目文件上传到服务器 `~/excel_translator`：

```bash
# 上传文件（在本地执行，替换 your-server-ip）
scp -r ./* admin@your-server-ip:~/excel_translator/
```

### 3. 安装 Python 依赖

```bash
cd ~/excel_translator

# 创建虚拟环境
python3 -m venv .venv

# 激活虚拟环境
source .venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 4. 配置 secrets.toml

复制模板文件并填入你的 API 密钥和密码：

```bash
cp .streamlit/secrets.toml.template .streamlit/secrets.toml
nano .streamlit/secrets.toml  # 编辑配置
```

> **提示**：模板中的模型经验证翻译效果不错，也可自行探索其他模型。

### 5. 启动 Streamlit 服务

```bash
cd ~/excel_translator

# 添加执行权限
chmod +x start.sh

# 启动服务（启动 3 个实例：8501, 8502, 8503）
./start.sh start

# 查看状态
./start.sh status

# 查看日志
cat .pids/8501.log
```

### 6. 配置 nginx

```bash
# 复制 nginx 配置
sudo cp nginx.conf /etc/nginx/sites-available/translate

# 创建软链接启用配置
sudo ln -s /etc/nginx/sites-available/translate /etc/nginx/sites-enabled/

# 删除默认配置（可选，避免8080端口冲突）
# 说明：如果 nginx 默认配置使用了8080端口，会导致冲突
# 此操作仅删除 sites-enabled 中的软链接，sites-available/default 保留
sudo rm /etc/nginx/sites-enabled/default

# 测试配置是否正确
sudo nginx -t

# 重新加载 nginx
sudo systemctl reload nginx
```

### 7. 开放防火墙端口

在服务器的防火墙/安全组中开放 8080 端口。

### 8. 访问服务

打开浏览器访问：`http://your-server-ip:8080`

## 服务管理

```bash
cd ~/excel_translator

# 启动
./start.sh start

# 停止
./start.sh stop

# 重启
./start.sh restart

# 查看状态
./start.sh status
```

## 开机自启（可选）

推荐直接使用仓库内提供的 `excel-translator.service`：

```bash
cd ~/excel-translator
chmod +x start.sh

# 如有需要，先按实际部署路径/用户修改 service 文件中的 User 和 WorkingDirectory
sudo cp excel-translator.service /etc/systemd/system/excel-translator.service

# 启用开机自启
sudo systemctl daemon-reload
sudo systemctl enable excel-translator.service
sudo systemctl start excel-translator.service
sudo systemctl status excel-translator.service
```

> 说明：由于 `start.sh` 会自行拉起多个后台 Streamlit 进程，systemd 建议使用 `Type=oneshot + RemainAfterExit=yes`，比 `Type=forking` 更稳定。

## 常见问题

### Q: 页面打开后无法交互/一直加载

检查 nginx 的 WebSocket 配置是否正确，确保 `nginx.conf` 中包含：

```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

### Q: 上传大文件失败

检查 nginx 配置中的 `client_max_body_size`，默认设置为 100M。

### Q: 翻译超时

检查 nginx 配置中的 `proxy_read_timeout`，默认设置为 300s（5分钟）。

### Q: 查看错误日志

```bash
# Streamlit 日志
cat ~/excel_translator/.pids/8501.log

# nginx 日志
sudo tail -f /var/log/nginx/error.log
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `app.py` | 主应用代码 |
| `requirements.txt` | Python 依赖 |
| `nginx.conf` | nginx 配置文件 |
| `start.sh` | 服务启动脚本 |
| `.streamlit/secrets.toml` | 配置文件（密码、API密钥等） |
