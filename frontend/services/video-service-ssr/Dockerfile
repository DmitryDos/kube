FROM node:20-alpine

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy workspace files
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY services/video-service-bff/package.json ./services/video-service-bff/
COPY services/auth-service-bff/package.json ./services/auth-service-bff/
COPY services/video-service-ssr/package.json ./services/video-service-ssr/
COPY tsconfig.*.json ./

# Install dependencies
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile

# Copy source code
COPY services/video-service-ssr ./services/video-service-ssr

# Build and run
WORKDIR /app/services/video-service-ssr
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm run build

# Copy static files to standalone directory (required for standalone mode)
# The standalone server expects .next/static to be accessible
RUN mkdir -p .next/standalone/.next && \
    cp -r .next/static .next/standalone/.next/static

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Run from the standalone directory
WORKDIR /app/services/video-service-ssr/.next/standalone
CMD ["node", "server.js"]
