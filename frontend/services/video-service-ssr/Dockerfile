FROM node:20-alpine AS base

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy workspace root files
COPY frontend/package.json frontend/pnpm-workspace.yaml frontend/.npmrc ./
COPY frontend/pnpm-lock.yaml* ./

# Copy service package.json
COPY frontend/services/web/package.json ./services/web/

# Copy tsconfig files
COPY frontend/tsconfig.base.json frontend/tsconfig.checks.json ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# Copy workspace root files
COPY frontend/package.json frontend/pnpm-workspace.yaml frontend/.npmrc ./
COPY frontend/pnpm-lock.yaml* ./

# Copy service source code
COPY frontend/services/web ./services/web

# Copy tsconfig files
COPY frontend/tsconfig.base.json frontend/tsconfig.checks.json ./

# Copy node_modules from deps
COPY --from=deps /app/node_modules ./node_modules

ENV NEXT_TELEMETRY_DISABLED 1

WORKDIR /app/services/web
RUN pnpm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/services/web/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/services/web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/services/web/.next/static ./.next/static

USER nextjs

EXPOSE 3002

ENV PORT 3002
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]

