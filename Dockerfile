# 使用官方Python基础镜像
FROM python:3.10-slim

# 设置环境变量，防止Python生成.pyc文件，并确保输出实时刷新
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 安装必要的依赖
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# 下载并安装Google Chrome
RUN wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O chrome.deb && \
    apt-get update && apt-get install -y ./chrome.deb --no-install-recommends && \
    rm chrome.deb && \
    rm -rf /var/lib/apt/lists/*

# 设置Chromium浏览器路径为环境变量
ENV BROWSER_PATH=/usr/bin/google-chrome

# 创建工作目录
WORKDIR /app

# 复制需求文件并安装Python依赖
COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 5000

# 设置Flask运行环境变量
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=5000

# 启动Flask应用
CMD ["python", "cf_pass_api.py"]