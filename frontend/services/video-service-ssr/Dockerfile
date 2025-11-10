FROM node:20-alpine

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy only workspace config files (needed for pnpm workspace)
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY tsconfig.*.json ./

# Copy only video-service-ssr package.json (we only need this service)
COPY services/video-service-ssr/package.json ./services/video-service-ssr/

# Install dependencies only for video-service-ssr using pnpm filter
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile --filter ./services/video-service-ssr

# Copy source code only for video-service-ssr
COPY services/video-service-ssr ./services/video-service-ssr

# Build and run
WORKDIR /app/services/video-service-ssr
ENV NEXT_TELEMETRY_DISABLED=1
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
