# ==================== 构建阶段 ====================
FROM node:22-alpine AS builder

WORKDIR /app

# 配置 npm 镜像源（国内用户）
RUN npm config set registry https://registry.npmmirror.com

# 复制 package 文件
COPY package*.json ./

# 安装依赖
RUN npm ci

# 复制所有源代码
COPY . .

# 构建前端（Vue + Vite）
RUN npm run build

# ==================== 运行阶段 ====================
FROM node:22-alpine AS runtime

WORKDIR /app

# 配置 npm 镜像源
RUN npm config set registry https://registry.npmmirror.com

# 复制 package 文件（只复制生产依赖）
COPY package*.json ./

# 安装生产依赖
RUN npm ci --only=production && npm cache clean --force

# 从构建阶段复制前端构建结果
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server ./server

# 创建数据目录
RUN mkdir -p /app/data

# 暴露端口
EXPOSE 3001

# 启动服务
CMD ["node", "server/index.js"]
