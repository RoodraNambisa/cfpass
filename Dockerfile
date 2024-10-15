# 使用官方 Python 运行时作为基础镜像，选择更轻量的版本
FROM python:3.10-slim AS base

# 设置环境变量，防止 Python 生成 .pyc 文件，并确保输出实时刷新
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    BROWSER_PATH=/usr/bin/google-chrome \
    FLASK_APP=app.py \
    FLASK_RUN_HOST=0.0.0.0 \
    FLASK_RUN_PORT=5000

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装 Google Chrome
RUN wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O chrome.deb \
    && apt-get update \
    && apt-get install -y ./chrome.deb --no-install-recommends \
    && rm chrome.deb \
    && rm -rf /var/lib/apt/lists/*

# 使用官方轻量级 Python 镜像作为构建阶段
FROM base AS builder

# 创建工作目录
WORKDIR /app

# 安非缓存 Python 依赖
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# 生产镜像阶段
FROM base AS production

# 创建非 root 用户以增强安全性
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# 设置工作目录
WORKDIR /app

# 复制 Python 依赖
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 复制应用代码
COPY . .

# 更改文件所有权
RUN chown -R appuser:appgroup /app

# 切换到非 root 用户
USER appuser

# 暴露端口
EXPOSE 5000

# 使用 Gunicorn 作为生产环境的 WSGI 服务器
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "cf_pass_api:app", "--workers", "4", "--threads", "2"]