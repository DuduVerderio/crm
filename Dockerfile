FROM oven/bun:1.3-alpine AS builder

WORKDIR /app

# Copy monorepo structure
COPY bun.lockb .
COPY package.json .
COPY apps/api ./apps/api
COPY packages/db ./packages/db
COPY packages/env ./packages/env

# Install dependencies
RUN bun install --frozen-lockfile

# Generate Prisma client
ARG DATABASE_URL
ENV DATABASE_URL=${DATABASE_URL}
RUN cd packages/db && bunx prisma generate

# Build the API
WORKDIR /app/apps/api
RUN bun run build

# Runtime image
FROM oven/bun:1.3-alpine

WORKDIR /app

# Copy built files from builder
COPY --from=builder /app/apps/api/dist ./dist
COPY --from=builder /app/apps/api/api ./api
COPY --from=builder /app/packages/db/src/generated ./packages/db/src/generated
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json .

# Copy env setup (required by packages/env)
COPY packages/env ./packages/env

EXPOSE 3000

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD bun -e "const res = await fetch('http://localhost:3000/health'); process.exit(res.ok ? 0 : 1)"

CMD ["bun", "run", "api/index.ts"]
