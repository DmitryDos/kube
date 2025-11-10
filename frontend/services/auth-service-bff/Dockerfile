FROM node:20-alpine

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy only workspace config files (needed for pnpm workspace)
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY tsconfig.*.json ./

# Copy only auth-service-bff package.json (we only need this service)
COPY services/auth-service-bff/package.json ./services/auth-service-bff/

# Install dependencies only for auth-service-bff using pnpm filter
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile --filter ./services/auth-service-bff

# Copy source code only for auth-service-bff
COPY services/auth-service-bff ./services/auth-service-bff

# Build
WORKDIR /app/services/auth-service-bff
RUN pnpm run build

# Run
EXPOSE 3003
ENV PORT=3003
CMD ["node", "dist/main.js"]
