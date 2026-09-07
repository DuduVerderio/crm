FROM oven/bun:1.3-alpine

WORKDIR /app

# Copy the whole monorepo (node_modules/.git/etc excluded via .dockerignore)
# so bun can resolve every workspace referenced by the lockfile.
COPY . .

RUN bun install --frozen-lockfile

ARG DATABASE_URL
ENV DATABASE_URL=${DATABASE_URL}
RUN cd packages/db && bunx prisma generate

WORKDIR /app/apps/api

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
  CMD bun -e "const res = await fetch('http://localhost:3000/health'); process.exit(res.ok ? 0 : 1)"

CMD ["bun", "run", "api/index.ts"]
