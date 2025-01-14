FROM python:3.10-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    BROWSER_PATH=/usr/bin/google-chrome \
    FLASK_APP=app.py \
    FLASK_RUN_HOST=0.0.0.0 \
    FLASK_RUN_PORT=5000

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

#RUN wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O chrome.deb \
RUN wget -q "https://repo.debiancn.org/pool/main/g/google-chrome-stable/google-chrome-stable_124.0.6367.60-1_amd64.deb" -O chrome.deb \
    && apt-get update \
    && apt-get install -y ./chrome.deb --no-install-recommends \
    && rm chrome.deb \
    && rm -rf /var/lib/apt/lists/*

FROM base AS builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

FROM base AS production


WORKDIR /app

COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY . .


# 暴露端口
EXPOSE 5000

# 使用 Gunicorn 作为生产环境的 WSGI 服务器
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "cf_pass_api:app","--workers", "2", "--threads", "1", "--timeout", "60"]
