# ==================== 构建阶段 ====================
FROM node:22-alpine AS builder

WORKDIR /app

# 安装构建工具和 Python（关键修复）
RUN apk add --no-cache \
    python3 \
    py3-pip \
    make \
    g++ \
    gcc \
    musl-dev \
    && ln -sf /usr/bin/python3 /usr/bin/python

# 配置 npm 镜像源（国内用户）
RUN npm config set registry https://registry.npmmirror.com

# 复制 package 文件
COPY package*.json ./

# 安装所有依赖（包括开发依赖，以便构建）
RUN npm ci

# 复制所有源代码
COPY . .

# 构建前端（Vue + Vite）
RUN npm run build

# ==================== 运行阶段 ====================
FROM node:22-alpine AS runtime

WORKDIR /app

# 安装运行时必要的依赖（包括 Python，用于 node-pty）
RUN apk add --no-cache \
    python3 \
    sqlite

# 配置 npm 镜像源
RUN npm config set registry https://registry.npmmirror.com

# 从构建阶段复制生产依赖（node_modules）和构建结果
# 注意：这里直接复制 node_modules，避免在运行时重新安装
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server ./server
COPY --from=builder /app/package.json ./package.json
# 创建数据目录
RUN mkdir -p /app/data

# 暴露端口
EXPOSE 3001

# 启动服务
CMD ["node", "server/index.js"]
