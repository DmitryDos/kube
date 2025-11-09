# syntax=docker/dockerfile:1.4
FROM node:20-alpine AS base

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy workspace root files
COPY package.json pnpm-workspace.yaml .npmrc* ./
COPY pnpm-lock.yaml* ./

# Copy all service package.json files
COPY services/video-service-bff/package.json ./services/video-service-bff/
COPY services/auth-service-bff/package.json ./services/auth-service-bff/
COPY services/video-service-ssr/package.json ./services/video-service-ssr/

# Copy tsconfig files
COPY tsconfig.checks.json tsconfig.ssr.json tsconfig.bff.json ./

# Install all dependencies once for the entire workspace
# Use cache mount to share node_modules between builds
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# Copy workspace root files
COPY package.json pnpm-workspace.yaml .npmrc* ./
COPY pnpm-lock.yaml* ./

# Copy service source code
COPY services/auth-service-bff ./services/auth-service-bff
COPY services/video-service-bff/package.json ./services/video-service-bff/
COPY services/video-service-ssr/package.json ./services/video-service-ssr/

# Copy tsconfig files
COPY tsconfig.checks.json tsconfig.ssr.json tsconfig.bff.json ./

# Copy node_modules from deps
COPY --from=deps /app/node_modules ./node_modules

WORKDIR /app/services/auth-service-bff
RUN pnpm run build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

COPY --from=builder /app/services/auth-service-bff/dist ./dist
COPY --from=builder /app/services/auth-service-bff/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules

USER nestjs

EXPOSE 3003

ENV PORT=3003

CMD ["node", "dist/main.js"]
