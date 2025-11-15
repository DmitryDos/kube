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

# Stage 2: Build video-service-ssr
FROM base AS build

# Copy source code only for video-service-ssr
COPY services/video-service-ssr ./services/video-service-ssr

# Build and run
WORKDIR /app/services/video-service-ssr
ENV NEXT_TELEMETRY_DISABLED=1

# Build Next.js app
RUN pnpm run build

# Copy static files to standalone directory (required for standalone mode)
# The standalone output preserves workspace structure, so server.js is at services/video-service-ssr/server.js
RUN mkdir -p .next/standalone/services/video-service-ssr/.next && \
    cp -r .next/static .next/standalone/services/video-service-ssr/.next/static && \
    echo "Build verification complete"

EXPOSE 3004
ENV PORT=3004
ENV HOSTNAME="0.0.0.0"

# Run from the standalone directory where server.js is located
WORKDIR /app/services/video-service-ssr/.next/standalone/services/video-service-ssr
CMD ["node", "server.js"]
