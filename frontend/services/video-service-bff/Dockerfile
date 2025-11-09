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
COPY services/video-service-bff ./services/video-service-bff

# Build
WORKDIR /app/services/video-service-bff
RUN pnpm run build

# Run
EXPOSE 3002
ENV PORT=3002
CMD ["node", "dist/main.js"]
