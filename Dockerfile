# syntax=docker/dockerfile:1

# ================== FRONTEND BUILD ==================
FROM node:22-alpine AS frontend-build

WORKDIR /app
RUN apk add --no-cache git

COPY package.json package-lock.json ./
RUN npm ci --force

COPY . .
RUN npm run build

# ================== BACKEND ==================
FROM python:3.11-slim

# ================== ENV (TOP) ==================
ENV PYTHONUNBUFFERED=1 \
    ENV=prod \
    HOST=0.0.0.0 \
    PORT=10000 \

    # ===== GROQ =====
    OPENAI_API_BASE_URL=https://api.groq.com/openai/v1 \
    OPENAI_API_KEY=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 \
    OPENAI_API_MODEL=llama3-70b-8192 \

    # ===== WEBUI =====
    WEBUI_SECRET_KEY=change_this_secret \
    ENABLE_SIGNUP=false \
    DO_NOT_TRACK=true \
    ANONYMIZED_TELEMETRY=false \

    # ===== STORAGE =====
    DATA_DIR=/app/backend/data

# ================== SYSTEM DEPS ==================
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    ffmpeg \
    libsm6 \
    libxext6 \
    jq \
    && rm -rf /var/lib/apt/lists/*

# ================== WORKDIR ==================
WORKDIR /app/backend

# ================== INSTALL BACKEND ==================
COPY backend/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ================== COPY FILES ==================
COPY backend .
COPY --from=frontend-build /app/build /app/build

# ================== DATA DIR ==================
RUN mkdir -p /app/backend/data

# ================== PORT ==================
EXPOSE 8080

# ================== HEALTHCHECK ==================
HEALTHCHECK CMD curl --fail http://localhost:${PORT}/health || exit 1

# ================== START (FIXED FOR RENDER) ==================
CMD ["sh", "-c", "python -m open_webui serve --host 0.0.0.0 --port ${PORT:-10000}"]
