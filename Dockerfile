# ---------- Stage 1: Build Vue app ----------
FROM node:16-alpine AS builder

WORKDIR /app

# Copy manifest truoc de tan dung layer cache khi code thay doi
COPY package*.json ./
RUN npm ci --no-audit --no-fund

# Copy phan con lai va build
COPY . .
RUN npm run build

# ---------- Stage 2: Nginx runtime ----------
FROM nginx:stable-alpine

WORKDIR /usr/share/nginx/html
RUN rm -rf ./*

# Lay dist tu stage builder
COPY --from=builder /app/dist .

# Cau hinh Nginx tuy chinh (handle SPA routing)
COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
