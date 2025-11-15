# Stage 1: Base image with all dependencies installed
# This stage is identical across all services, so Docker can reuse the cache
FROM node:20-alpine AS base

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy workspace config files
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY tsconfig.*.json ./

# Copy all service package.json files to install all dependencies at once
COPY services/video-service-ssr/package.json ./services/video-service-ssr/
COPY services/video-service-bff/package.json ./services/video-service-bff/
COPY services/auth-service-bff/package.json ./services/auth-service-bff/

# Install all dependencies once for the entire workspace
# --shamefully-hoist to flatten node_modules (helps with some packages)
# --ignore-scripts to skip build scripts during install (faster)
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile --shamefully-hoist --ignore-scripts

# Stage 2: Build video-service-bff
FROM base AS build

# Copy source code only for video-service-bff
COPY services/video-service-bff ./services/video-service-bff

# Build
WORKDIR /app/services/video-service-bff
RUN pnpm run build

# Run
EXPOSE 3002
ENV PORT=3002
CMD ["node", "dist/main.js"]
