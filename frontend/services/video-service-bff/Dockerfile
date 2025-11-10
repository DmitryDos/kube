FROM node:20-alpine

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy only workspace config files (needed for pnpm workspace)
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY tsconfig.*.json ./

# Copy only video-service-bff package.json (we only need this service)
COPY services/video-service-bff/package.json ./services/video-service-bff/

# Install dependencies only for video-service-bff using pnpm filter
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile --filter ./services/video-service-bff

# Copy source code only for video-service-bff
COPY services/video-service-bff ./services/video-service-bff

# Build
WORKDIR /app/services/video-service-bff
RUN pnpm run build

# Run
EXPOSE 3002
ENV PORT=3002
CMD ["node", "dist/main.js"]
